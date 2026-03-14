package com.uvmonitor.app.worker

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import com.uvmonitor.app.data.AppDatabase
import com.uvmonitor.app.data.StoredForecastEntity
import com.uvmonitor.app.data.UVReadingEntity
import com.uvmonitor.app.model.UVStation
import com.uvmonitor.app.notification.UVNotificationManager
import com.uvmonitor.app.service.ARPANSAService
import com.uvmonitor.app.service.OpenMeteoService
import java.util.Calendar
import java.util.concurrent.TimeUnit

class UVRefreshWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        val prefs = applicationContext.getSharedPreferences("uv_monitor", Context.MODE_PRIVATE)
        val stationName = prefs.getString("station", null)
        val station = stationName?.let {
            try { UVStation.valueOf(it) } catch (_: Exception) { null }
        } ?: UVStation.SYDNEY

        val db = AppDatabase.getInstance(applicationContext)
        val dao = db.uvDao()
        val arpansa = ARPANSAService()
        val openMeteo = OpenMeteoService()
        val notificationManager = UVNotificationManager(applicationContext)

        try {
            // Fetch current UV
            val reading = arpansa.fetchCurrentUV(station)
            if (reading != null) {
                dao.insertReading(
                    UVReadingEntity(
                        stationId = station.code,
                        uvIndex = reading.uvIndex,
                        timestamp = System.currentTimeMillis()
                    )
                )
            }

            // Fetch forecast
            val forecast = openMeteo.fetchForecast(station)
            if (forecast != null) {
                val cal = Calendar.getInstance(station.timeZone)
                cal.set(Calendar.HOUR_OF_DAY, 0)
                cal.set(Calendar.MINUTE, 0)
                cal.set(Calendar.SECOND, 0)
                cal.set(Calendar.MILLISECOND, 0)

                dao.insertForecast(
                    StoredForecastEntity.from(station.code, cal.timeInMillis, forecast)
                )

                // Schedule notifications
                notificationManager.scheduleNotifications(forecast)
            }

            return Result.success()
        } catch (e: Exception) {
            return Result.retry()
        }
    }

    companion object {
        private const val WORK_NAME = "uv_refresh"

        fun schedule(context: Context) {
            val request = PeriodicWorkRequestBuilder<UVRefreshWorker>(
                15, TimeUnit.MINUTES
            ).build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,
                request
            )
        }
    }
}
