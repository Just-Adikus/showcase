import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:showcase/services/kiosk_service.dart'; // Импортируйте созданный сервис

class EnhancedKioskModeSettingsScreen extends StatefulWidget {
  @override
  _EnhancedKioskModeSettingsScreenState createState() =>
      _EnhancedKioskModeSettingsScreenState();
}

class _EnhancedKioskModeSettingsScreenState
    extends State<EnhancedKioskModeSettingsScreen> {
  bool _isKioskModeEnabled = false;
  bool _hideNavigationBar = true;
  bool _hideStatusBar = true;
  bool _preventTaskSwitching = true;
  bool _forceLandscape = true;
  bool _isDeviceOwner = false;
  bool _hasRootAccess = false;
  bool _isLoading = false;

  Map<String, dynamic> _permissions = {};

  @override
  void initState() {
    super.initState();
    _loadKioskSettings();
    _checkPermissions();
  }

  void _loadKioskSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bool kioskEnabled = await KioskService.isKioskModeEnabled();
      final bool deviceOwner = await KioskService.isDeviceOwner();

      setState(() {
        _isKioskModeEnabled = kioskEnabled;
        _isDeviceOwner = deviceOwner;
        _isLoading = false;
      });
    } catch (e) {
      print("Ошибка загрузки настроек: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _checkPermissions() async {
    try {
      final permissions = await KioskService.checkPermissions();
      setState(() {
        _permissions = permissions;
        _isDeviceOwner = permissions['isDeviceOwner'] ?? false;
        _hasRootAccess = permissions['hasRootAccess'] ?? false;
        _isKioskModeEnabled = permissions['isInLockTaskMode'] ?? false;
      });
    } catch (e) {
      print("Ошибка проверки разрешений: $e");
    }
  }

  void _saveKioskSettings() {
    // Здесь можно сохранить настройки в Hive или SharedPreferences
    // HiveService.saveKioskSettings(...)
  }

  void _navigateToProductList() {
    Navigator.pushReplacementNamed(context, '/products');
  }

  void _enableKioskMode() async {
    if (_isKioskModeEnabled) return;

    setState(() {
      _isLoading = true;
    });

    // Сначала применяем базовые настройки UI
    _applySystemUISettings();

    // Затем включаем Lock Task Mode
    final bool success = await KioskService.enableKioskMode();

    setState(() {
      _isKioskModeEnabled = success;
      _isLoading = false;
    });

    _saveKioskSettings();

    if (success) {
      _showSnackBar(
        "Lock Task Mode включен",
        Colors.green,
        action: SnackBarAction(
          label: "К товарам",
          textColor: Colors.white,
          onPressed: () => _navigateToProductList(),
        ),
      );
    } else {
      _showSnackBar(
        "Не удалось включить Lock Task Mode. Проверьте права Device Owner.",
        Colors.red,
      );
    }
  }

  void _disableKioskMode() async {
    if (!_isKioskModeEnabled) return;

    setState(() {
      _isLoading = true;
    });

    final bool success = await KioskService.disableKioskMode();

    if (success) {
      // Восстанавливаем все системные UI элементы
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );

      // Разрешаем все ориентации
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    setState(() {
      _isKioskModeEnabled = !success ? _isKioskModeEnabled : false;
      _isLoading = false;
    });

    _saveKioskSettings();

    _showSnackBar(
      success
          ? "Lock Task Mode выключен"
          : "Не удалось выключить Lock Task Mode",
      success ? Colors.orange : Colors.red,
    );
  }

  void _applySystemUISettings() {
    List<SystemUiOverlay> overlaysToHide = [];

    if (_hideStatusBar) {
      overlaysToHide.add(SystemUiOverlay.top);
    }

    if (_hideNavigationBar) {
      overlaysToHide.add(SystemUiOverlay.bottom);
    }

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: overlaysToHide.isEmpty ? [] : overlaysToHide,
    );

    // Фиксируем ориентацию экрана
    if (_forceLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  void _showExitKioskDialog() {
    if (!_isKioskModeEnabled) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final TextEditingController pinController = TextEditingController();

        return AlertDialog(
          title: Text("Выход из Lock Task Mode"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Введите PIN-код для выхода из Lock Task Mode:"),
              SizedBox(height: 16),
              TextField(
                controller: pinController,
                decoration: InputDecoration(
                  labelText: "PIN-код",
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text("Отмена"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text("Выйти"),
              onPressed: () {
                if (pinController.text == "1234") {
                  Navigator.pop(context);
                  _disableKioskMode();
                } else {
                  _showSnackBar("Неверный PIN-код", Colors.red);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, Color color, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, action: action),
    );
  }

  void _enableDeviceOwner() async {
    setState(() {
      _isLoading = true;
    });

    final bool success = await KioskService.enableDeviceOwner();

    setState(() {
      _isLoading = false;
    });

    if (success) {
      _showSnackBar("Device Owner активирован", Colors.green);
      _checkPermissions(); // Обновляем статус разрешений
    } else {
      _showSnackBar(
        "Не удалось активировать Device Owner. Убедитесь, что у вас есть root права.",
        Colors.red,
      );
    }
  }

  Widget _buildPermissionStatus() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Статус разрешений",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            _buildPermissionRow("Device Owner", _isDeviceOwner),
            _buildPermissionRow("Root доступ", _hasRootAccess),
            _buildPermissionRow("Lock Task Mode", _isKioskModeEnabled),

            if (!_isDeviceOwner) ...[
              SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _enableDeviceOwner,
                icon: Icon(Icons.admin_panel_settings),
                label: Text("Активировать Device Owner"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Для активации Lock Task Mode требуются права Device Owner",
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRow(String label, bool granted) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            granted ? Icons.check_circle : Icons.cancel,
            color: granted ? Colors.green : Colors.red,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Настройки Lock Task Mode")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Загрузка настроек..."),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Настройки Lock Task Mode"),
        leading:
            _isKioskModeEnabled
                ? IconButton(
                  icon: Icon(Icons.lock_open),
                  onPressed: _showExitKioskDialog,
                )
                : null,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Статус Lock Task Mode
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      _isKioskModeEnabled ? Icons.lock : Icons.lock_open,
                      color: _isKioskModeEnabled ? Colors.red : Colors.green,
                      size: 32,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Lock Task Mode",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            _isKioskModeEnabled ? "Активен" : "Неактивен",
                            style: TextStyle(
                              color:
                                  _isKioskModeEnabled
                                      ? Colors.red
                                      : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Статус разрешений
            _buildPermissionStatus(),

            SizedBox(height: 24),

            // Настройки UI
            Text(
              "Настройки интерфейса",
              style: Theme.of(context).textTheme.titleLarge,
            ),

            SizedBox(height: 16),

            // Скрыть статус-бар
            SwitchListTile(
              title: Text("Скрыть статус-бар"),
              subtitle: Text("Скрывает верхнюю панель с временем и батареей"),
              value: _hideStatusBar,
              onChanged:
                  _isKioskModeEnabled
                      ? null
                      : (value) {
                        setState(() {
                          _hideStatusBar = value;
                        });
                      },
            ),

            // Скрыть панель навигации
            SwitchListTile(
              title: Text("Скрыть панель навигации"),
              subtitle: Text("Скрывает нижнюю панель с кнопками навигации"),
              value: _hideNavigationBar,
              onChanged:
                  _isKioskModeEnabled
                      ? null
                      : (value) {
                        setState(() {
                          _hideNavigationBar = value;
                        });
                      },
            ),

            // Предотвратить переключение задач
            SwitchListTile(
              title: Text("Блокировать переключение приложений"),
              subtitle: Text("Полная блокировка выхода из приложения"),
              value: _preventTaskSwitching,
              onChanged:
                  _isKioskModeEnabled
                      ? null
                      : (value) {
                        setState(() {
                          _preventTaskSwitching = value;
                        });
                      },
            ),

            // Принудительный альбомный режим
            SwitchListTile(
              title: Text("Альбомный режим"),
              subtitle: Text(
                "Принудительно поворачивает экран в альбомный режим",
              ),
              value: _forceLandscape,
              onChanged:
                  _isKioskModeEnabled
                      ? null
                      : (value) {
                        setState(() {
                          _forceLandscape = value;
                        });
                      },
            ),

            SizedBox(height: 24),

            // Информационное сообщение
            if (_isKioskModeEnabled)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Column(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 28),
                    SizedBox(height: 8),
                    Text(
                      "АКТИВЕН LOCK TASK MODE",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Приложение заблокировано на экране. Системные кнопки отключены.\n" +
                          "Для выхода нажмите замок и введите PIN: 1234\n" +
                          "Режим экрана: " +
                          (_forceLandscape ? "Альбомный" : "Портретный"),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  ],
                ),
              ),

            if (!_isDeviceOwner && !_isKioskModeEnabled)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info, color: Colors.orange),
                    SizedBox(height: 8),
                    Text(
                      "Для работы Lock Task Mode необходимы права Device Owner",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "С root правами можно активировать Device Owner автоматически",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.orange.shade800),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 16),

            // Кнопки управления
            if (!_isKioskModeEnabled) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isDeviceOwner ? _enableKioskMode : null,
                      icon: Icon(Icons.lock),
                      label: Text("Включить Lock Task Mode"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isDeviceOwner ? Colors.red : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Кнопки в активном Lock Task Mode
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToProductList(),
                      icon: Icon(Icons.store),
                      label: Text("К товарам"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showExitKioskDialog,
                      icon: Icon(Icons.lock_open),
                      label: Text("Выключить"),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            SizedBox(height: 24),

            // Техническая информация
            ExpansionTile(
              title: Text("Техническая информация"),
              leading: Icon(Icons.info_outline),
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Lock Task Mode - это Android функция, которая:"),
                      SizedBox(height: 8),
                      Text("• Полностью блокирует выход из приложения"),
                      Text(
                        "• Отключает системные кнопки (Home, Back, Recents)",
                      ),
                      Text("• Предотвращает переключение между приложениями"),
                      Text("• Скрывает уведомления"),
                      Text("• Требует права Device Owner для работы"),
                      SizedBox(height: 12),
                      Text(
                        "Для активации Device Owner с root правами используется команда:\n"
                        "dpm set-device-owner com.example.showcase/.DeviceAdminReceiver",
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // При выходе из экрана настроек восстанавливаем UI, если Lock Task Mode не активен
    if (!_isKioskModeEnabled) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    super.dispose();
  }
}
