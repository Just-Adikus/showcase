package com.example.showcase

import android.app.admin.DeviceAdminReceiver
import android.app.admin.DevicePolicyManager   // ✅ добавил импорт
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.Toast

class DeviceAdminReceiver : DeviceAdminReceiver() {

    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Log.d("DeviceAdmin", "Device Admin включен")
        
        // Проверяем статус Device Owner
        val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val isDeviceOwner = dpm.isDeviceOwnerApp(context.packageName)
        
        Log.d("DeviceAdmin", "Device Owner статус: $isDeviceOwner")
        
        if (isDeviceOwner) {
            Toast.makeText(context, "Device Owner активирован успешно!", Toast.LENGTH_LONG).show()
        } else {
            Toast.makeText(context, "Device Admin включен, но Device Owner не активирован", Toast.LENGTH_LONG).show()
        }
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        Log.d("DeviceAdmin", "Device Admin выключен")
        Toast.makeText(context, "Device Admin деактивирован", Toast.LENGTH_SHORT).show()
    }

    override fun onDisableRequested(context: Context, intent: Intent): CharSequence? {
        Log.d("DeviceAdmin", "Запрос на деактивацию Device Admin")
        return "Это приложение требует права Device Admin для работы Kiosk режима"
    }

    override fun onLockTaskModeEntering(context: Context, intent: Intent, pkg: String) {
        super.onLockTaskModeEntering(context, intent, pkg)
        Log.d("DeviceAdmin", "Вход в Lock Task Mode для пакета: $pkg")
        Toast.makeText(context, "Киоск-режим активирован", Toast.LENGTH_SHORT).show()
    }

    override fun onLockTaskModeExiting(context: Context, intent: Intent) {
        super.onLockTaskModeExiting(context, intent)
        Log.d("DeviceAdmin", "Выход из Lock Task Mode")
        Toast.makeText(context, "Киоск-режим деактивирован", Toast.LENGTH_SHORT).show()
    }
}
