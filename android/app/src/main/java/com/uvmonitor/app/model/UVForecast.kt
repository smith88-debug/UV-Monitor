package com.uvmonitor.app.model

import java.util.Date

data class UVForecastPoint(
    val time: Date,
    val uvIndex: Double
)

data class UVForecast(
    val points: List<UVForecastPoint>
) {
    val peakUV: Double
        get() = points.maxOfOrNull { it.uvIndex } ?: 0.0

    val protectionStartTime: Date?
        get() = points.firstOrNull { it.uvIndex >= 3.0 }?.time

    val protectionEndTime: Date?
        get() = points.lastOrNull { it.uvIndex >= 3.0 }?.time
}
