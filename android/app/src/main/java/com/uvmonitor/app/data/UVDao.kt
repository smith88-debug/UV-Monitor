package com.uvmonitor.app.data

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface UVDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertReading(reading: UVReadingEntity)

    @Query("SELECT * FROM uv_readings WHERE stationId = :stationId AND timestamp >= :since ORDER BY timestamp DESC")
    suspend fun getReadings(stationId: String, since: Long): List<UVReadingEntity>

    @Query("SELECT * FROM uv_readings WHERE stationId = :stationId AND timestamp BETWEEN :dayStart AND :dayEnd ORDER BY timestamp ASC")
    suspend fun getReadingsForDay(stationId: String, dayStart: Long, dayEnd: Long): List<UVReadingEntity>

    @Query("DELETE FROM uv_readings WHERE timestamp < :cutoff")
    suspend fun deleteOldReadings(cutoff: Long)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertForecast(forecast: StoredForecastEntity)

    @Query("SELECT * FROM stored_forecasts WHERE stationId = :stationId AND date = :date LIMIT 1")
    suspend fun getForecast(stationId: String, date: Long): StoredForecastEntity?

    @Query("DELETE FROM stored_forecasts WHERE date < :cutoff")
    suspend fun deleteOldForecasts(cutoff: Long)
}
