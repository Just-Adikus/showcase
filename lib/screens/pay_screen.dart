import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../utils/image_utils.dart';

class MultiProductPayScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final double totalAmount;

  MultiProductPayScreen({required this.cartItems, required this.totalAmount});

  @override
  _MultiProductPayScreenState createState() => _MultiProductPayScreenState();
}

class _MultiProductPayScreenState extends State<MultiProductPayScreen> {
  bool isLoading = true;
  bool isCancelling = false;
  bool isPaid = false;
  bool isWaitingForDoorClose = false;
  bool isClosingDoor = false;
  Timer? _statusTimer;
  Timer? _sessionTimeoutTimer;
  Timer? _doorCloseTimer;
  Timer? _doorCloseMessageTimer;
  Timer? _bluetoothRetryTimer;
  int itemID = 0;
  final int sessionTimeoutSeconds = 120;
  int remainingSeconds = 120;
  String? errorMessage;
  final _bluetoothClassicPlugin = BluetoothClassic();
  String? _bluetoothDeviceAddress;
  bool _isBluetoothConnected = false;
  int _bluetoothRetryCount = 0;
  final int _maxBluetoothRetries = 3;

  @override
  void initState() {
    super.initState();
    _loadBluetoothSettings();
    _checkStatus();
  }

  Future<void> _writeLog(String message) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/bluetooth_log.txt');
      final timestamp = DateTime.now().toIso8601String();
      final logEntry = '[$timestamp] $message\n';
      print(logEntry); // Output to console for adb logcat
      await file.writeAsString(logEntry, mode: FileMode.append);
    } catch (e) {
      print('Ошибка записи лога: $e');
    }
  }

  Future<void> _loadBluetoothSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _bluetoothDeviceAddress = prefs.getString('bluetoothDeviceAddress');
      });
      await _writeLog(
        'Загружен адрес Bluetooth устройства: $_bluetoothDeviceAddress',
      );
    } catch (e, stackTrace) {
      await _writeLog(
        'Ошибка загрузки настроек Bluetooth: $e\nСтек вызовов: $stackTrace',
      );
      print("Ошибка загрузки настроек Bluetooth: $e");
    }
  }

  Future<void> _connectBluetooth() async {
    if (_isBluetoothConnected) {
      await _writeLog('Bluetooth уже подключен');
      return;
    }

    if (_bluetoothDeviceAddress == null || _bluetoothDeviceAddress!.isEmpty) {
      await _writeLog('Ошибка: Устройство Bluetooth не настроено');
      setState(() {
        errorMessage = "Устройство Bluetooth не настроено";
      });
      return;
    }

    try {
      await _writeLog(
        'Попытка подключения к устройству: $_bluetoothDeviceAddress',
      );
      await _bluetoothClassicPlugin
          .connect(
            _bluetoothDeviceAddress!,
            "00001101-0000-1000-8000-00805f9b34fb",
          )
          .timeout(
            Duration(seconds: 5),
            onTimeout: () {
              throw TimeoutException('Превышено время ожидания подключения');
            },
          );

      await _writeLog('Подключение успешно');
      _isBluetoothConnected = true;
      _bluetoothRetryCount = 0;
    } catch (e, stackTrace) {
      await _writeLog(
        'Ошибка при подключении Bluetooth: $e\nСтек вызовов: $stackTrace',
      );
      _isBluetoothConnected = false;

      // Try to disconnect in case connection is in an inconsistent state
      try {
        await _bluetoothClassicPlugin.disconnect();
        await _writeLog('Bluetooth отключен после ошибки подключения');
      } catch (disconnectError) {
        await _writeLog('Ошибка при отключении Bluetooth: $disconnectError');
      }

      throw e; // Re-throw the error for the caller to handle
    }
  }

  Future<void> _disconnectBluetooth() async {
    if (!_isBluetoothConnected) {
      await _writeLog('Bluetooth уже отключен');
      return;
    }

    try {
      await _bluetoothClassicPlugin.disconnect();
      await _writeLog('Bluetooth отключен');
      _isBluetoothConnected = false;
    } catch (e, stackTrace) {
      await _writeLog(
        'Ошибка при отключении Bluetooth: $e\nСтек вызовов: $stackTrace',
      );
    }
  }

  Future<bool> _sendBluetoothSignal(String signal) async {
    await _writeLog('Начало отправки Bluetooth сигнала: $signal');

    if (_bluetoothDeviceAddress == null || _bluetoothDeviceAddress!.isEmpty) {
      await _writeLog('Ошибка: Устройство Bluetooth не настроено');
      setState(() {
        errorMessage = "Устройство Bluetooth не настроено";
      });
      return false;
    }

    try {
      // Connect if not already connected
      if (!_isBluetoothConnected) {
        await _connectBluetooth();
      }

      await _writeLog('Отправка сигнала: $signal');
      await _bluetoothClassicPlugin
          .write(signal)
          .timeout(
            Duration(seconds: 3),
            onTimeout: () {
              throw TimeoutException(
                'Превышено время ожидания отправки сигнала',
              );
            },
          );

      await _writeLog('Сигнал успешно отправлен: $signal');
      return true;
    } catch (e, stackTrace) {
      await _writeLog(
        'Ошибка при отправке Bluetooth сигнала: $e\nСтек вызовов: $stackTrace',
      );

      // Set error message only if sending "0" signal fails and we've tried multiple times
      if (signal == "0" && _bluetoothRetryCount >= _maxBluetoothRetries) {
        setState(() {
          errorMessage =
              "Не удалось закрыть дверь. Пожалуйста, закройте дверь вручную.";
        });
      } else if (signal == "1") {
        setState(() {
          errorMessage = "Ошибка при отправке сигнала через Bluetooth: $e";
        });
      }

      // Always try to disconnect when there's an error
      try {
        await _disconnectBluetooth();
      } catch (disconnectError) {
        await _writeLog(
          'Ошибка при отключении Bluetooth после ошибки отправки: $disconnectError',
        );
      }

      return false;
    }
  }

  Future _checkStatus() async {
    try {
      final response = await _sendRequest("status");
      final data = jsonDecode(response.body);

      if (data["status"] == "idle" && data["error"] == "ok") {
        setState(() => isLoading = false);
        _startPaymentSession();
      } else if (data["status"] == "session") {
        await _sendRequest("cancel");
        await _sendRequest("complete");
        _startPaymentSession();
      } else if (data["status"] == "paid") {
        setState(() {
          isLoading = false;
          isPaid = true;
        });
        await _completeTransaction();
        await _writeLog('Отправка сигнала 1 для открытия двери');
        bool signalSent = await _sendBluetoothSignal("1");
        await _writeLog(
          'Результат отправки сигнала 1: ${signalSent ? "Успех" : "Неудача"}',
        );

        if (signalSent) {
          _startDoorSequence();
        } else {
          _showErrorDialog(
            "Не удалось открыть дверь. Пожалуйста, обратитесь к администратору.",
          );
        }
      } else {
        await _sendRequest("complete");
        setState(() => isLoading = false);
        _startPaymentSession();
      }
    } catch (e, stackTrace) {
      await _writeLog(
        'Ошибка при проверке статуса: $e\nСтек вызовов: $stackTrace',
      );
      setState(() {
        isLoading = false;
        errorMessage = "Ошибка соединения с терминалом";
      });
    }
  }

  void _startDoorSequence() {
    _writeLog('Начало последовательности открытия/закрытия двери');
    setState(() {
      isWaitingForDoorClose = true;
    });

    _doorCloseMessageTimer = Timer(Duration(seconds: 5), () async {
      await _writeLog('Показ сообщения о закрытии двери');
      setState(() {
        isClosingDoor = true;
        errorMessage = "Закройте дверь после того как получили товар";
      });

      await _writeLog('Перед отправкой сигнала 0');
      await _sendCloseDoorSignal();
    });
  }

  Future<void> _sendCloseDoorSignal() async {
    _bluetoothRetryCount = 0;
    await _attemptCloseDoor();
  }

  Future<void> _attemptCloseDoor() async {
    if (_bluetoothRetryCount >= _maxBluetoothRetries) {
      await _writeLog(
        'Превышено максимальное количество попыток отправки сигнала 0',
      );

      // Even if we failed to send signal, continue with the flow
      _finalizeTransaction();
      return;
    }

    _bluetoothRetryCount++;
    await _writeLog('Попытка #$_bluetoothRetryCount отправки сигнала 0');

    bool signalSent = await _sendBluetoothSignal("0");
    await _writeLog(
      'Результат отправки сигнала 0: ${signalSent ? "Успех" : "Неудача"}',
    );

    if (signalSent) {
      _finalizeTransaction();
    } else {
      // If we failed, wait a bit and try again
      await _writeLog('Ожидание перед повторной попыткой отправки сигнала 0');
      _bluetoothRetryTimer = Timer(Duration(seconds: 1), () async {
        await _attemptCloseDoor();
      });
    }
  }

  void _finalizeTransaction() {
    _writeLog(
      'Финализация транзакции, возврат на предыдущий экран через 5 секунд',
    );
    Timer(Duration(seconds: 5), () {
      _writeLog('Возврат на предыдущий экран');
      if (mounted) Navigator.pop(context, true);
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Ошибка"),
          content: Text(message),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pop(context, false);
              },
            ),
          ],
        );
      },
    );
  }

  void _startPaymentSession() {
    setState(() {
      isLoading = true;
      remainingSeconds = sessionTimeoutSeconds;
      errorMessage = null;
    });

    itemID = (itemID + 1) % 65536;

    String itemNames = widget.cartItems
        .map((item) => "${item.product.name} x${item.quantity}")
        .join(", ");

    _sendRequest("request", {
          "amount": widget.totalAmount,
          "item": itemID,
          "name_kz": "Заказ #$itemID",
          "name_ru":
              itemNames.length > 30
                  ? itemNames.substring(0, 27) + "..."
                  : itemNames,
        })
        .then((response) {
          final data = jsonDecode(response.body);

          if (data["error"] == "ok") {
            setState(() => isLoading = false);

            _statusTimer = Timer.periodic(
              Duration(seconds: 1),
              _checkPaymentStatus,
            );

            _sessionTimeoutTimer = Timer.periodic(Duration(seconds: 1), (
              timer,
            ) {
              setState(() {
                if (remainingSeconds > 0) {
                  remainingSeconds--;
                } else {
                  _cancelSession("Время ожидания оплаты истекло");
                  timer.cancel();
                }
              });
            });
          } else {
            setState(() {
              isLoading = false;
              errorMessage = "Ошибка создания платежа: ${data["error"]}";
            });
          }
        })
        .catchError((e, stackTrace) {
          _writeLog('Ошибка создания платежа: $e\nСтек вызовов: $stackTrace');
          setState(() {
            isLoading = false;
            errorMessage = "Ошибка соединения с терминалом";
          });
        });
  }

  Future _checkPaymentStatus(Timer timer) async {
    try {
      final response = await _sendRequest("status");
      final data = jsonDecode(response.body);

      if (data["status"] == "paid" && data["error"] == "ok") {
        timer.cancel();
        _sessionTimeoutTimer?.cancel();

        setState(() => isPaid = true);
        await _completeTransaction();

        await _writeLog('Отправка сигнала 1 для открытия двери');
        bool signalSent = await _sendBluetoothSignal("1");
        await _writeLog(
          'Результат отправки сигнала 1: ${signalSent ? "Успех" : "Неудача"}',
        );

        if (signalSent) {
          _startDoorSequence();
        } else {
          _showErrorDialog(
            "Не удалось открыть дверь. Пожалуйста, обратитесь к администратору.",
          );
        }
      } else if (data["status"] == "canceled") {
        _cancelSession("Платеж был отменен");
      } else if (data["status"] != "session") {
        _cancelSession("Ошибка при обработке платежа");
      }
    } catch (e, stackTrace) {
      await _writeLog(
        'Ошибка при проверке статуса оплаты: $e\nСтек вызовов: $stackTrace',
      );
      _cancelSession("Ошибка соединения с терминалом");
    }
  }

  Future _cancelSession([String? reason]) async {
    setState(() {
      isCancelling = true;
      errorMessage = reason != null ? reason : "Отмена платежа...";
    });

    _statusTimer?.cancel();
    _sessionTimeoutTimer?.cancel();

    try {
      await _sendRequest("cancel");
      await _completeTransaction();

      await Future.delayed(Duration(milliseconds: 500));

      if (mounted) {
        if (reason != null && reason != "Отмена платежа...") {
          setState(() {
            isCancelling = false;
            errorMessage = reason;
          });

          Timer(Duration(seconds: 2), () {
            if (mounted) Navigator.pop(context, false);
          });
        } else {
          Navigator.pop(context, false);
        }
      }
    } catch (e, stackTrace) {
      await _writeLog(
        'Ошибка при отмене сессии: $e\nСтек вызовов: $stackTrace',
      );
      setState(() {
        isCancelling = false;
        errorMessage = "Ошибка при отмене сессии: $e";
      });

      Timer(Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context, false);
      });
    }
  }

  Future _completeTransaction() async {
    try {
      await _sendRequest("complete");
    } catch (e, stackTrace) {
      await _writeLog(
        'Ошибка при завершении транзакции: $e\nСтек вызовов: $stackTrace',
      );
      setState(() {
        errorMessage = "Ошибка при завершении транзакции: $e";
      });
    }
  }

  Future<http.Response> _sendRequest(
    String act, [
    Map<String, dynamic>? extra,
  ]) {
    final Map<String, dynamic> body = {"act": act};
    if (extra != null) body.addAll(extra);

    return http.post(
      Uri.parse('http://192.168.1.1/httppay'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
  }

  @override
  void dispose() {
    _writeLog('Уничтожение виджета, отключение Bluetooth');
    _statusTimer?.cancel();
    _sessionTimeoutTimer?.cancel();
    _doorCloseTimer?.cancel();
    _doorCloseMessageTimer?.cancel();
    _bluetoothRetryTimer?.cancel();

    _disconnectBluetooth();

    if (!isPaid && !isLoading) {
      _sendRequest("cancel").then((_) => _sendRequest("complete"));
    }
    super.dispose();
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSecs = seconds % 60;
    return '$minutes:${remainingSecs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            if (!isCancelling && !isWaitingForDoorClose) {
              _cancelSession("Отмена платежа...");
            }
          },
        ),
        title: Text('Оплата заказа'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isPaid && !isWaitingForDoorClose)
                Icon(Icons.check_circle, color: Colors.green, size: 100)
              else if (isPaid && isWaitingForDoorClose && !isClosingDoor)
                Icon(Icons.door_sliding, color: Colors.blue, size: 100)
              else if (isPaid && isWaitingForDoorClose && isClosingDoor)
                Icon(Icons.door_back_door, color: Colors.orange, size: 100)
              else if (isLoading || isCancelling)
                CircularProgressIndicator()
              else if (!isLoading && !isCancelling)
                Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: loadImage(
                      "assets/images/qr.jpg",
                      width: 250,
                      height: 250,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              SizedBox(height: 24),
              if (isPaid && !isWaitingForDoorClose)
                Text(
                  'Оплата прошла успешно!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                )
              else if (isPaid && isWaitingForDoorClose && !isClosingDoor)
                Text(
                  'Дверь открыта! Заберите товар.',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                )
              else if (isPaid && isWaitingForDoorClose && isClosingDoor)
                Text(
                  'Закройте дверь после того как получили товар',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                )
              else if (isLoading)
                Text('Подготовка платежа...')
              else if (isCancelling)
                Text('Отменяем сессию...')
              else
                Column(
                  children: [
                    Text(
                      'Сумма к оплате: ${widget.totalAmount.toStringAsFixed(2)} ₸',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Отсканируйте QR-код для оплаты',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Время до отмены: ${_formatTime(remainingSeconds)}',
                      style: TextStyle(
                        color:
                            remainingSeconds < 30 ? Colors.red : Colors.black,
                        fontWeight:
                            remainingSeconds < 30
                                ? FontWeight.bold
                                : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              SizedBox(height: 30),
              if (!isPaid && !isLoading && !isCancelling)
                ElevatedButton(
                  onPressed: () => _cancelSession("Отмена платежа..."),
                  child: Text('Отменить оплату'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              if (errorMessage != null && !isClosingDoor) ...[
                Spacer(),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
