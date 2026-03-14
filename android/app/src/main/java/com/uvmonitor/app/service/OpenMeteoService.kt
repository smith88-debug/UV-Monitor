package com.uvmonitor.app.service

import com.uvmonitor.app.model.UVForecast
import com.uvmonitor.app.model.UVForecastPoint
import com.uvmonitor.app.model.UVStation
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone
import java.util.concurrent.TimeUnit

class OpenMeteoService {
    private val client = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(15, TimeUnit.SECONDS)
        .build()

    suspend fun fetchForecast(station: UVStation): UVForecast? = withContext(Dispatchers.IO) {
        try {
            val url = "https://api.open-meteo.com/v1/forecast" +
                "?latitude=${station.coordinate.latitude}" +
                "&longitude=${station.coordinate.longitude}" +
                "&hourly=uv_index" +
                "&timezone=auto" +
                "&forecast_days=1"

            val request = Request.Builder().url(url).build()
            val response = client.newCall(request).execute()
            if (!response.isSuccessful) return@withContext null

            val json = response.body?.string() ?: return@withContext null
            parseResponse(json, station)
        } catch (e: Exception) {
            null
        }
    }

    private fun parseResponse(json: String, station: UVStation): UVForecast? {
        return try {
            val root = JSONObject(json)
            val hourly = root.getJSONObject("hourly")
            val times = hourly.getJSONArray("time")
            val uvValues = hourly.getJSONArray("uv_index")

            val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm", Locale.US)
            dateFormat.timeZone = station.timeZone

            val points = mutableListOf<UVForecastPoint>()
            for (i in 0 until times.length()) {
                val timeStr = times.getString(i)
                val uvIndex = if (uvValues.isNull(i)) 0.0 else uvValues.getDouble(i)
                val date = dateFormat.parse(timeStr)
                if (date != null) {
                    points.add(UVForecastPoint(date, uvIndex))
                }
            }

            UVForecast(points)
        } catch (e: Exception) {
            null
        }
    }
}
