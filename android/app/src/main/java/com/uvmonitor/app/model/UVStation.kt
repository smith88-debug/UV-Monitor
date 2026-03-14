package com.uvmonitor.app.model

import java.util.TimeZone

data class UVStationCoordinate(val latitude: Double, val longitude: Double)

enum class UVStation(
    val displayName: String,
    val code: String,
    val coordinate: UVStationCoordinate,
    val timeZoneId: String
) {
    ADELAIDE("Adelaide", "ade", UVStationCoordinate(-34.9285, 138.6007), "Australia/Adelaide"),
    ALICE_SPRINGS("Alice Springs", "ali", UVStationCoordinate(-23.6980, 133.8807), "Australia/Darwin"),
    BRISBANE("Brisbane", "bri", UVStationCoordinate(-27.4698, 153.0251), "Australia/Brisbane"),
    CANBERRA("Canberra", "can", UVStationCoordinate(-35.2802, 149.1310), "Australia/Sydney"),
    DARWIN("Darwin", "dar", UVStationCoordinate(-12.4634, 130.8456), "Australia/Darwin"),
    EMERALD("Emerald", "eme", UVStationCoordinate(-23.5275, 148.1642), "Australia/Brisbane"),
    GOLD_COAST("Gold Coast", "gol", UVStationCoordinate(-28.0167, 153.4000), "Australia/Brisbane"),
    MELBOURNE("Melbourne", "mel", UVStationCoordinate(-37.8136, 144.9631), "Australia/Melbourne"),
    NEWCASTLE("Newcastle", "new", UVStationCoordinate(-32.9283, 151.7817), "Australia/Sydney"),
    PERTH("Perth", "per", UVStationCoordinate(-31.9505, 115.8605), "Australia/Perth"),
    SYDNEY("Sydney", "syd", UVStationCoordinate(-33.8688, 151.2093), "Australia/Sydney"),
    TOWNSVILLE("Townsville", "tow", UVStationCoordinate(-19.2590, 146.8169), "Australia/Brisbane"),

    // Antarctic research stations
    CASEY("Casey", "cas", UVStationCoordinate(-66.2823, 110.5278), "Antarctica/Casey"),
    DAVIS("Davis", "dav", UVStationCoordinate(-68.5772, 77.9696), "Antarctica/Davis"),
    KINGSTON("Kingston", "kin", UVStationCoordinate(-42.9884, 147.3311), "Australia/Hobart"),
    MACQUARIE_ISLAND("Macquarie Island", "mac", UVStationCoordinate(-54.6208, 158.8556), "Australia/Hobart"),
    MAWSON("Mawson", "maw", UVStationCoordinate(-67.6027, 62.8738), "Antarctica/Mawson");

    val timeZone: TimeZone get() = TimeZone.getTimeZone(timeZoneId)

    companion object {
        val australianStations: List<UVStation> = listOf(
            ADELAIDE, ALICE_SPRINGS, BRISBANE, CANBERRA, DARWIN, EMERALD,
            GOLD_COAST, MELBOURNE, NEWCASTLE, PERTH, SYDNEY, TOWNSVILLE
        )

        val researchStations: List<UVStation> = listOf(
            CASEY, DAVIS, KINGSTON, MACQUARIE_ISLAND, MAWSON
        )

        fun nearest(latitude: Double, longitude: Double): UVStation {
            return entries.minBy { station ->
                val dLat = station.coordinate.latitude - latitude
                val dLon = station.coordinate.longitude - longitude
                dLat * dLat + dLon * dLon
            }
        }
    }
}
