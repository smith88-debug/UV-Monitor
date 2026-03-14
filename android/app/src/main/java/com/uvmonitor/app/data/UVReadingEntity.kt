package com.uvmonitor.app.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "uv_readings")
data class UVReadingEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val stationId: String,
    val uvIndex: Double,
    val timestamp: Long
)
