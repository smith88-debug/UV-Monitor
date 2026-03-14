package com.uvmonitor.app

import android.app.Application
import com.uvmonitor.app.notification.UVNotificationManager
import com.uvmonitor.app.worker.UVRefreshWorker

class UVMonitorApp : Application() {
    override fun onCreate() {
        super.onCreate()

        // Create notification channel
        UVNotificationManager(this).createNotificationChannel()

        // Schedule background refresh
        UVRefreshWorker.schedule(this)
    }
}
