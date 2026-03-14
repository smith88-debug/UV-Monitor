package com.uvmonitor.app.service

import com.uvmonitor.app.model.UVStation
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import org.xmlpull.v1.XmlPullParser
import org.xmlpull.v1.XmlPullParserFactory
import java.io.StringReader
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.concurrent.TimeUnit

data class ARPANSAReading(
    val stationName: String,
    val uvIndex: Double,
    val dateTime: Date?,
    val status: String
)

class ARPANSAService {
    private val client = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(15, TimeUnit.SECONDS)
        .build()

    suspend fun fetchCurrentUV(station: UVStation): ARPANSAReading? = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder()
                .url("https://uvdata.arpansa.gov.au/xml/uvvalues.xml")
                .build()

            val response = client.newCall(request).execute()
            if (!response.isSuccessful) return@withContext null

            val xml = response.body?.string() ?: return@withContext null
            parseXml(xml, station)
        } catch (e: Exception) {
            null
        }
    }

    private fun parseXml(xml: String, station: UVStation): ARPANSAReading? {
        val factory = XmlPullParserFactory.newInstance()
        val parser = factory.newPullParser()
        parser.setInput(StringReader(xml))

        var inTargetLocation = false
        var currentIndex: Double? = null
        var currentStatus: String? = null
        var currentDateTime: String? = null
        var currentTag = ""
        var locationId: String? = null

        while (parser.eventType != XmlPullParser.END_DOCUMENT) {
            when (parser.eventType) {
                XmlPullParser.START_TAG -> {
                    currentTag = parser.name
                    if (currentTag == "location") {
                        locationId = parser.getAttributeValue(null, "id")
                        inTargetLocation = locationId?.equals(station.displayName, ignoreCase = true) == true
                        currentIndex = null
                        currentStatus = null
                        currentDateTime = null
                    }
                }
                XmlPullParser.TEXT -> {
                    if (inTargetLocation) {
                        val text = parser.text.trim()
                        when (currentTag) {
                            "index" -> currentIndex = text.toDoubleOrNull()
                            "status" -> currentStatus = text
                            "utcdatetime" -> currentDateTime = text
                        }
                    }
                }
                XmlPullParser.END_TAG -> {
                    if (parser.name == "location" && inTargetLocation) {
                        if (currentIndex != null) {
                            val date = currentDateTime?.let { parseDateTime(it) }
                            return ARPANSAReading(
                                stationName = station.displayName,
                                uvIndex = currentIndex,
                                dateTime = date,
                                status = currentStatus ?: ""
                            )
                        }
                        inTargetLocation = false
                    }
                    currentTag = ""
                }
            }
            parser.next()
        }
        return null
    }

    private fun parseDateTime(dateTimeStr: String): Date? {
        return try {
            val format = SimpleDateFormat("yyyy/MM/dd HH:mm", Locale.US)
            format.timeZone = TimeZone.getTimeZone("UTC")
            format.parse(dateTimeStr)
        } catch (e: Exception) {
            null
        }
    }
}
