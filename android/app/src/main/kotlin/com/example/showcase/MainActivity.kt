package com.example.showcase

import android.app.Activity
import android.app.ActivityManager
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.KeyEvent
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class MainActivity : FlutterActivity(), MethodCallHandler {
    private val CHANNEL = "com.example.showcase/kiosk_mode"
    private lateinit var devicePolicyManager: DevicePolicyManager
    private lateinit var adminComponentName: ComponentName
    private var isInLockTaskMode = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler(this)
        
        // Инициализация Device Policy Manager
        devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        adminComponentName = ComponentName(this, DeviceAdminReceiver::class.java)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Предотвращаем скриншоты и запись экрана
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "enableKioskMode" -> {
                val success = enableKioskMode()
                result.success(success)
            }
            "disableKioskMode" -> {
                val success = disableKioskMode()
                result.success(success)
            }
            "isKioskModeEnabled" -> {
                result.success(isInLockTaskMode())
            }
            "isDeviceOwner" -> {
                result.success(isDeviceOwner())
            }
            "enableDeviceOwner" -> {
                val success = enableDeviceOwner()
                result.success(success)
            }
            "checkPermissions" -> {
                result.success(checkAllPermissions())
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun enableKioskMode(): Boolean {
        return try {
            if (isDeviceOwner()) {
                // Устанавливаем это приложение как Lock Task Package
                devicePolicyManager.setLockTaskPackages(
                    adminComponentName,
                    arrayOf(packageName)
                )
                
                // Запускаем Lock Task Mode
                startLockTask()
                isInLockTaskMode = true
                
                Log.d("KioskMode", "Lock Task Mode включен")
                true
            } else {
                Log.e("KioskMode", "Приложение не является Device Owner")
                false
            }
        } catch (e: Exception) {
            Log.e("KioskMode", "Ошибка при включении Kiosk Mode: ${e.message}")
            false
        }
    }

    private fun disableKioskMode(): Boolean {
        return try {
            if (isInLockTaskMode()) {
                stopLockTask()
                isInLockTaskMode = false
                
                Log.d("KioskMode", "Lock Task Mode выключен")
                true
            } else {
                Log.w("KioskMode", "Lock Task Mode уже выключен")
                true
            }
        } catch (e: Exception) {
            Log.e("KioskMode", "Ошибка при выключении Kiosk Mode: ${e.message}")
            false
        }
    }

    private fun isInLockTaskMode(): Boolean {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        return try {
            activityManager.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE
        } catch (e: Exception) {
            false
        }
    }

    private fun isDeviceOwner(): Boolean {
        return devicePolicyManager.isDeviceOwnerApp(packageName)
    }

    private fun enableDeviceOwner(): Boolean {
        // Эта функция требует выполнения ADB команды с root правами
        // dpm set-device-owner com.example.showcase/.DeviceAdminReceiver
        return try {
            val process = Runtime.getRuntime().exec(arrayOf(
                "su", "-c", 
                "dpm set-device-owner ${packageName}/.DeviceAdminReceiver"
            ))
            val exitCode = process.waitFor()
            
            if (exitCode == 0) {
                Log.d("KioskMode", "Device Owner установлен успешно")
                true
            } else {
                Log.e("KioskMode", "Ошибка установки Device Owner: exit code $exitCode")
                false
            }
        } catch (e: Exception) {
            Log.e("KioskMode", "Исключение при установке Device Owner: ${e.message}")
            false
        }
    }

    private fun checkAllPermissions(): Map<String, Boolean> {
        return mapOf(
            "isDeviceOwner" to isDeviceOwner(),
            "isInLockTaskMode" to isInLockTaskMode(),
            "hasRootAccess" to hasRootAccess()
        )
    }

    private fun hasRootAccess(): Boolean {
        return try {
            val process = Runtime.getRuntime().exec("su")
            process.outputStream.write("exit\n".toByteArray())
            process.outputStream.flush()
            process.waitFor() == 0
        } catch (e: Exception) {
            false
        }
    }

    // Блокируем системные кнопки в Lock Task Mode
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (isInLockTaskMode()) {
            when (keyCode) {
                KeyEvent.KEYCODE_BACK,
                KeyEvent.KEYCODE_HOME,
                KeyEvent.KEYCODE_APP_SWITCH -> {
                    Log.d("KioskMode", "Системная кнопка заблокирована: $keyCode")
                    return true // Блокируем кнопку
                }
            }
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onBackPressed() {
        if (isInLockTaskMode()) {
            // В Lock Task Mode блокируем кнопку назад
            Log.d("KioskMode", "Кнопка назад заблокирована в Kiosk Mode")
            return
        }
        super.onBackPressed()
    }

    override fun onPause() {
        super.onPause()
        if (isInLockTaskMode()) {
            // Предотвращаем сворачивание приложения
            Log.d("KioskMode", "Попытка свернуть приложение заблокирована")
        }
    }

    override fun onStop() {
        super.onStop()
        if (isInLockTaskMode()) {
            // Возвращаем приложение на передний план
            val intent = Intent(this, MainActivity::class.java)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            startActivity(intent)
        }
    }
}