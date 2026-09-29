package com.carrementweb.fraya_mobile

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import io.flutter.app.FlutterApplication

class FrayaApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = getSystemService(NotificationManager::class.java)
        val soundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        val audioAttributes = AudioAttributes.Builder()
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .build()

        listOf(
            ChannelSpec(
                id = ALERTS_CHANNEL_ID,
                name = "Fraya Alerts",
                description = "Notifications urgentes Fraya",
            ),
            ChannelSpec(
                id = LEGACY_PUSH_CHANNEL_ID,
                name = "Fraya Notifications",
                description = "Notifications Fraya",
            ),
            ChannelSpec(
                id = FCM_FALLBACK_CHANNEL_ID,
                name = "Fraya Notifications",
                description = "Notifications Fraya",
            ),
        ).forEach { spec ->
            if (manager.getNotificationChannel(spec.id) == null) {
                manager.createNotificationChannel(
                    NotificationChannel(
                        spec.id,
                        spec.name,
                        NotificationManager.IMPORTANCE_HIGH,
                    ).apply {
                        description = spec.description
                        enableVibration(true)
                        vibrationPattern = longArrayOf(0L, 250L, 150L, 250L)
                        setSound(soundUri, audioAttributes)
                        setShowBadge(true)
                        lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                    },
                )
            }
        }
    }

    private data class ChannelSpec(
        val id: String,
        val name: String,
        val description: String,
    )

    companion object {
        const val ALERTS_CHANNEL_ID = "fraya_alerts_v2"
        private const val LEGACY_PUSH_CHANNEL_ID = "fraya_push_channel"
        private const val FCM_FALLBACK_CHANNEL_ID = "fcm_fallback_notification_channel"
    }
}
