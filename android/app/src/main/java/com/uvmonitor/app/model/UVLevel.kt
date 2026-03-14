package com.uvmonitor.app.model

import androidx.compose.ui.graphics.Color

enum class UVLevel(
    val label: String,
    val color: Color,
    val protectionAdvice: String,
    val needsProtection: Boolean
) {
    LOW(
        label = "Low",
        color = Color(0xFF4CAF50),
        protectionAdvice = "No protection needed. Enjoy the outdoors!",
        needsProtection = false
    ),
    MODERATE(
        label = "Moderate",
        color = Color(0xFFFFC107),
        protectionAdvice = "Wear sunscreen, a hat and sunglasses.",
        needsProtection = true
    ),
    HIGH(
        label = "High",
        color = Color(0xFFFF9800),
        protectionAdvice = "Wear SPF 30+ sunscreen, protective clothing, hat and sunglasses. Seek shade during midday.",
        needsProtection = true
    ),
    VERY_HIGH(
        label = "Very High",
        color = Color(0xFFF44336),
        protectionAdvice = "Minimise sun exposure between 10 am and 2 pm. Apply SPF 50+ sunscreen, wear protective clothing.",
        needsProtection = true
    ),
    EXTREME(
        label = "Extreme",
        color = Color(0xFF9C27B0),
        protectionAdvice = "Avoid being outside during midday hours. Shirt, sunscreen, hat, sunglasses and shade are essential.",
        needsProtection = true
    );

    companion object {
        fun fromUVIndex(index: Double): UVLevel = when {
            index < 3.0 -> LOW
            index < 6.0 -> MODERATE
            index < 8.0 -> HIGH
            index < 11.0 -> VERY_HIGH
            else -> EXTREME
        }
    }
}
