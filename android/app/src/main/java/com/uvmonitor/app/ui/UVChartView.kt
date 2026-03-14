package com.uvmonitor.app.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.uvmonitor.app.model.UVForecast
import com.uvmonitor.app.model.UVForecastPoint
import com.uvmonitor.app.ui.theme.ForecastBlue
import com.uvmonitor.app.ui.theme.MeasuredOrange
import com.uvmonitor.app.ui.theme.UVExtreme
import com.uvmonitor.app.ui.theme.UVHigh
import com.uvmonitor.app.ui.theme.UVLow
import com.uvmonitor.app.ui.theme.UVModerate
import com.uvmonitor.app.ui.theme.UVVeryHigh
import java.util.Calendar
import java.util.TimeZone

@Composable
fun UVChartView(
    forecast: UVForecast?,
    measuredReadings: List<UVForecastPoint>,
    isToday: Boolean,
    timeZone: TimeZone,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier.fillMaxWidth()) {
        Text(
            text = "UV Forecast",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.padding(bottom = 8.dp)
        )

        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(220.dp)
        ) {
            Canvas(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(220.dp)
            ) {
                val chartLeft = 40f
                val chartRight = size.width - 16f
                val chartTop = 8f
                val chartBottom = size.height - 30f
                val chartWidth = chartRight - chartLeft
                val chartHeight = chartBottom - chartTop

                val startHour = 5
                val endHour = 21
                val totalHours = endHour - startHour
                val maxUV = 16f

                // Draw risk zone backgrounds
                drawRiskZones(chartLeft, chartTop, chartWidth, chartHeight, maxUV)

                // Draw protection threshold line at UV 3
                val thresholdY = chartTop + chartHeight * (1f - 3f / maxUV)
                drawLine(
                    color = Color(0xFFFF5722).copy(alpha = 0.6f),
                    start = Offset(chartLeft, thresholdY),
                    end = Offset(chartRight, thresholdY),
                    strokeWidth = 1.5f,
                    pathEffect = PathEffect.dashPathEffect(floatArrayOf(8f, 4f))
                )

                // Draw forecast line (dashed blue)
                if (forecast != null) {
                    drawDataLine(
                        points = forecast.points,
                        timeZone = timeZone,
                        startHour = startHour,
                        totalHours = totalHours,
                        maxUV = maxUV,
                        chartLeft = chartLeft,
                        chartTop = chartTop,
                        chartWidth = chartWidth,
                        chartHeight = chartHeight,
                        color = ForecastBlue,
                        dashed = true
                    )
                }

                // Draw measured line (solid orange)
                if (measuredReadings.isNotEmpty()) {
                    drawDataLine(
                        points = measuredReadings,
                        timeZone = timeZone,
                        startHour = startHour,
                        totalHours = totalHours,
                        maxUV = maxUV,
                        chartLeft = chartLeft,
                        chartTop = chartTop,
                        chartWidth = chartWidth,
                        chartHeight = chartHeight,
                        color = MeasuredOrange,
                        dashed = false
                    )
                }

                // Draw current time indicator (today only)
                if (isToday) {
                    val cal = Calendar.getInstance(timeZone)
                    val currentHour = cal.get(Calendar.HOUR_OF_DAY) + cal.get(Calendar.MINUTE) / 60f
                    if (currentHour in startHour.toFloat()..endHour.toFloat()) {
                        val x = chartLeft + chartWidth * (currentHour - startHour) / totalHours
                        drawLine(
                            color = Color.Gray.copy(alpha = 0.5f),
                            start = Offset(x, chartTop),
                            end = Offset(x, chartBottom),
                            strokeWidth = 2f
                        )
                    }
                }

                // Draw Y-axis labels
                val yLabels = listOf(0, 3, 6, 8, 11, 14)
                val paint = android.graphics.Paint().apply {
                    textSize = 24f
                    color = android.graphics.Color.GRAY
                    textAlign = android.graphics.Paint.Align.RIGHT
                }
                for (label in yLabels) {
                    val y = chartTop + chartHeight * (1f - label / maxUV)
                    drawContext.canvas.nativeCanvas.drawText(
                        label.toString(),
                        chartLeft - 8f,
                        y + 8f,
                        paint
                    )
                }

                // Draw X-axis labels (2-hour intervals)
                val xPaint = android.graphics.Paint().apply {
                    textSize = 22f
                    color = android.graphics.Color.GRAY
                    textAlign = android.graphics.Paint.Align.CENTER
                }
                for (hour in startHour..endHour step 2) {
                    val x = chartLeft + chartWidth * (hour - startHour).toFloat() / totalHours
                    val label = if (hour == 0 || hour == 12) {
                        if (hour == 0) "12AM" else "12PM"
                    } else if (hour < 12) {
                        "${hour}AM"
                    } else {
                        "${hour - 12}PM"
                    }
                    drawContext.canvas.nativeCanvas.drawText(
                        label,
                        x,
                        chartBottom + 22f,
                        xPaint
                    )
                }
            }
        }

        // Legend
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(top = 8.dp),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            LegendItem(color = ForecastBlue, label = "Predicted", dashed = true)
            LegendItem(
                color = MeasuredOrange,
                label = "Measured",
                dashed = false,
                modifier = Modifier.padding(start = 24.dp)
            )
        }
    }
}

@Composable
private fun LegendItem(
    color: Color,
    label: String,
    dashed: Boolean,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(10.dp)
                .background(color, CircleShape)
        )
        Text(
            text = label,
            fontSize = 12.sp,
            color = Color.Gray,
            modifier = Modifier.padding(start = 4.dp)
        )
    }
}

private fun DrawScope.drawRiskZones(
    chartLeft: Float,
    chartTop: Float,
    chartWidth: Float,
    chartHeight: Float,
    maxUV: Float
) {
    data class Zone(val low: Float, val high: Float, val color: Color)
    val zones = listOf(
        Zone(0f, 3f, UVLow),
        Zone(3f, 6f, UVModerate),
        Zone(6f, 8f, UVHigh),
        Zone(8f, 11f, UVVeryHigh),
        Zone(11f, maxUV, UVExtreme)
    )
    for (zone in zones) {
        val top = chartTop + chartHeight * (1f - zone.high / maxUV)
        val bottom = chartTop + chartHeight * (1f - zone.low / maxUV)
        drawRect(
            color = zone.color.copy(alpha = 0.1f),
            topLeft = Offset(chartLeft, top),
            size = androidx.compose.ui.geometry.Size(chartWidth, bottom - top)
        )
    }
}

private fun DrawScope.drawDataLine(
    points: List<UVForecastPoint>,
    timeZone: TimeZone,
    startHour: Int,
    totalHours: Int,
    maxUV: Float,
    chartLeft: Float,
    chartTop: Float,
    chartWidth: Float,
    chartHeight: Float,
    color: Color,
    dashed: Boolean
) {
    if (points.size < 2) return

    val pathEffect = if (dashed) PathEffect.dashPathEffect(floatArrayOf(10f, 6f)) else null

    val mapped = points.mapNotNull { point ->
        val cal = Calendar.getInstance(timeZone)
        cal.time = point.time
        val hour = cal.get(Calendar.HOUR_OF_DAY) + cal.get(Calendar.MINUTE) / 60f
        if (hour < startHour || hour > startHour + totalHours) return@mapNotNull null
        val x = chartLeft + chartWidth * (hour - startHour) / totalHours
        val y = chartTop + chartHeight * (1f - point.uvIndex.toFloat() / maxUV)
        Offset(x, y)
    }

    for (i in 0 until mapped.size - 1) {
        drawLine(
            color = color,
            start = mapped[i],
            end = mapped[i + 1],
            strokeWidth = 2.5f,
            pathEffect = pathEffect
        )
    }
}
