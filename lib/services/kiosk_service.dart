import 'package:flutter/services.dart';

class KioskService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.showcase/kiosk_mode',
  );

  /// Включить киоск-режим (Lock Task Mode)
  static Future<bool> enableKioskMode() async {
    try {
      final bool result = await _channel.invokeMethod('enableKioskMode');
      return result;
    } on PlatformException catch (e) {
      print("Ошибка включения киоск-режима: ${e.message}");
      return false;
    }
  }

  /// Выключить киоск-режим (Lock Task Mode)
  static Future<bool> disableKioskMode() async {
    try {
      final bool result = await _channel.invokeMethod('disableKioskMode');
      return result;
    } on PlatformException catch (e) {
      print("Ошибка выключения киоск-режима: ${e.message}");
      return false;
    }
  }

  /// Проверить, включен ли киоск-режим
  static Future<bool> isKioskModeEnabled() async {
    try {
      final bool result = await _channel.invokeMethod('isKioskModeEnabled');
      return result;
    } on PlatformException catch (e) {
      print("Ошибка проверки статуса киоск-режима: ${e.message}");
      return false;
    }
  }

  /// Проверить, является ли приложение Device Owner
  static Future<bool> isDeviceOwner() async {
    try {
      final bool result = await _channel.invokeMethod('isDeviceOwner');
      return result;
    } on PlatformException catch (e) {
      print("Ошибка проверки Device Owner: ${e.message}");
      return false;
    }
  }

  /// Попытаться активировать Device Owner (требует root)
  static Future<bool> enableDeviceOwner() async {
    try {
      final bool result = await _channel.invokeMethod('enableDeviceOwner');
      return result;
    } on PlatformException catch (e) {
      print("Ошибка активации Device Owner: ${e.message}");
      return false;
    }
  }

  /// Проверить все необходимые разрешения и статусы
  static Future<Map<String, dynamic>> checkPermissions() async {
    try {
      final Map<Object?, Object?> result = await _channel.invokeMethod(
        'checkPermissions',
      );
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      print("Ошибка проверки разрешений: ${e.message}");
      return {
        'isDeviceOwner': false,
        'isInLockTaskMode': false,
        'hasRootAccess': false,
      };
    }
  }
}
