import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KioskModeSettingsScreen extends StatefulWidget {
  @override
  _KioskModeSettingsScreenState createState() =>
      _KioskModeSettingsScreenState();
}

class _KioskModeSettingsScreenState extends State<KioskModeSettingsScreen> {
  bool _isKioskModeEnabled = false;
  bool _hideNavigationBar = true;
  bool _hideStatusBar = true;
  bool _preventTaskSwitching = true;
  bool _forceLandscape = true;

  // Храним изначальное состояние системных UI
  List<SystemUiOverlay> _originalOverlays = SystemUiOverlay.values;

  @override
  void initState() {
    super.initState();
    _loadKioskSettings();
  }

  void _loadKioskSettings() {
    // Здесь можно загрузить сохраненные настройки из Hive или SharedPreferences
    // Пока используем значения по умолчанию
    setState(() {
      _isKioskModeEnabled = false;
    });
  }

  void _saveKioskSettings() {
    // Здесь можно сохранить настройки в Hive или SharedPreferences
    // HiveService.saveKioskSettings(...)
  }

  void _navigateToProductList() {
    Navigator.pushReplacementNamed(context, '/products');
    // Или если используете MaterialPageRoute:
    // Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(builder: (context) => ProductListPage()),
    // );
  }

  void _enableKioskMode() {
    if (_isKioskModeEnabled) return;

    List<SystemUiOverlay> overlaysToHide = [];

    if (!_hideStatusBar) {
      overlaysToHide.add(SystemUiOverlay.top);
    }

    if (!_hideNavigationBar) {
      overlaysToHide.add(SystemUiOverlay.bottom);
    }

    // Скрываем системные UI элементы
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: overlaysToHide,
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

    setState(() {
      _isKioskModeEnabled = true;
    });

    _saveKioskSettings();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Киоск-режим включен"),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: "К товарам",
          textColor: Colors.white,
          onPressed: () => _navigateToProductList(),
        ),
      ),
    );
  }

  void _disableKioskMode() {
    if (!_isKioskModeEnabled) return;

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

    setState(() {
      _isKioskModeEnabled = false;
    });

    _saveKioskSettings();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Киоск-режим выключен"),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showExitKioskDialog() {
    if (!_isKioskModeEnabled) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final TextEditingController pinController = TextEditingController();

        return AlertDialog(
          title: Text("Выход из киоск-режима"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Введите PIN-код для выхода из киоск-режима:"),
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
                // Простая проверка PIN-кода (в реальном приложении используйте более безопасный способ)
                if (pinController.text == "1234") {
                  Navigator.pop(context);
                  _disableKioskMode();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Неверный PIN-код"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Настройки киоск-режима"),
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
            // Статус киоск-режима
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
                            "Статус киоск-режима",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            _isKioskModeEnabled ? "Включен" : "Выключен",
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

            SizedBox(height: 24),

            // Настройки киоск-режима
            Text("Настройки", style: Theme.of(context).textTheme.titleLarge),

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
              subtitle: Text("Запрещает переход к другим приложениям"),
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
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info, color: Colors.orange),
                    SizedBox(height: 8),
                    Text(
                      "Для выхода из киоск-режима нажмите на замок в верхнем левом углу и введите PIN-код: 1234\n" +
                          (_forceLandscape
                              ? "Режим: Альбомный"
                              : "Режим: Портретный"),
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
                      onPressed: _enableKioskMode,
                      icon: Icon(Icons.lock),
                      label: Text("Включить киоск-режим"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Кнопки в активном киоск-режиме
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToProductList(),
                      icon: Icon(Icons.store),
                      label: Text("Перейти к товарам"),
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

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // При выходе из экрана настроек восстанавливаем UI, если киоск-режим не активен
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
