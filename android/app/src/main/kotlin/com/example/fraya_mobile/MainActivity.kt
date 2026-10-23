package com.carrementweb.fraya_mobile

import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.speech.tts.TextToSpeech
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity() {
    // L'application est en français : le guidage du Navigation SDK (consignes écrites et voix) suit la langue
    // de l'activité, pas celle du téléphone, qui peut être en anglais.
    override fun attachBaseContext(newBase: Context) {
        val french = Locale("fr", "FR")
        Locale.setDefault(french)
        val configuration = Configuration(newBase.resources.configuration)
        configuration.setLocale(french)
        super.attachBaseContext(newBase.createConfigurationContext(configuration))
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Installation des données vocales françaises, nécessaires à la narration de la navigation.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TTS_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "installFrenchVoice") {
                    try {
                        startActivity(
                            Intent(TextToSpeech.Engine.ACTION_INSTALL_TTS_DATA)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                        )
                        result.success(true)
                    } catch (error: Exception) {
                        result.success(false)
                    }
                } else {
                    result.notImplemented()
                }
            }
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
                else -> result.notImplemented()
            }
        }
    }

    companion object {
        private const val TTS_CHANNEL = "fraya_mobile/tts"
        private const val DRIVER_PRESENCE_CHANNEL =
            "fraya_mobile/driver_presence"
    }
}
