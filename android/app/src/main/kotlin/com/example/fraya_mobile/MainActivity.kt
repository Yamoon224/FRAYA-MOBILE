package com.carrementweb.fraya_mobile

import android.content.Intent
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DRIVER_PRESENCE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    DriverPresenceForegroundService.start(this)
                    result.success(null)
                }
                "stop" -> {
                    DriverPresenceForegroundService.stop(this)
                    result.success(null)
                }
                "isIgnoringBatteryOptimizations" -> {
                    val powerManager = getSystemService(PowerManager::class.java)
                    result.success(powerManager.isIgnoringBatteryOptimizations(packageName))
                }
                "openBatteryOptimizationSettings" -> {
                    try {
                        // Écran de liste des optimisations : aucune permission spéciale requise.
                        startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
                        result.success(true)
                    } catch (error: Exception) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    companion object {
        private const val DRIVER_PRESENCE_CHANNEL =
            "fraya_mobile/driver_presence"
    }
}
