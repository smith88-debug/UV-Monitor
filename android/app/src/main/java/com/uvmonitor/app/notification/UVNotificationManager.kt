package com.uvmonitor.app.notification

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.uvmonitor.app.R
import com.uvmonitor.app.model.UVForecast

class UVNotificationManager(private val context: Context) {

    companion object {
        private const val CHANNEL_ID = "uv_alerts"
        private const val NOTIFICATION_ID_RISING = 1001
        private const val NOTIFICATION_ID_HIGH = 1002
    }

    fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            context.getString(R.string.notification_channel_name),
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = context.getString(R.string.notification_channel_description)
        }

        val manager = context.getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }

    fun scheduleNotifications(forecast: UVForecast) {
        if (!hasNotificationPermission()) return

        val peakUV = forecast.peakUV

        if (peakUV >= 3.0) {
            showNotification(
                id = NOTIFICATION_ID_RISING,
                title = "UV Rising — Apply Sunscreen",
                body = "UV index is reaching moderate levels. Apply sunscreen before heading outdoors."
            )
        }

        if (peakUV >= 6.0) {
            showNotification(
                id = NOTIFICATION_ID_HIGH,
                title = "High UV — Seek Shade",
                body = "UV index is high. Minimise sun exposure and seek shade where possible."
            )
        }
    }

    private fun showNotification(id: Int, title: String, body: String) {
        if (!hasNotificationPermission()) return

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .build()

        NotificationManagerCompat.from(context).notify(id, notification)
    }

    private fun hasNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                context, Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }
}
