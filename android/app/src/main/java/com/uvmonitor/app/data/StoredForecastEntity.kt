package com.uvmonitor.app.data

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.uvmonitor.app.model.UVForecast
import com.uvmonitor.app.model.UVForecastPoint
import java.util.Date

data class SerializableForecastPoint(
    val time: Long,
    val uvIndex: Double
)

@Entity(tableName = "stored_forecasts")
data class StoredForecastEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val stationId: String,
    val date: Long,
    val pointsJson: String
) {
    fun toUVForecast(): UVForecast {
        val type = object : TypeToken<List<SerializableForecastPoint>>() {}.type
        val points: List<SerializableForecastPoint> = Gson().fromJson(pointsJson, type)
        return UVForecast(
            points = points.map { UVForecastPoint(Date(it.time), it.uvIndex) }
        )
    }

    companion object {
        fun from(stationId: String, date: Long, forecast: UVForecast): StoredForecastEntity {
            val serializable = forecast.points.map {
                SerializableForecastPoint(it.time.time, it.uvIndex)
            }
            return StoredForecastEntity(
                stationId = stationId,
                date = date,
                pointsJson = Gson().toJson(serializable)
            )
        }
    }
}
