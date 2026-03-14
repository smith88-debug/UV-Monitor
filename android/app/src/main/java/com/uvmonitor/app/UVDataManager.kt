package com.uvmonitor.app

import android.app.Application
import android.content.Context
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.uvmonitor.app.data.AppDatabase
import com.uvmonitor.app.data.StoredForecastEntity
import com.uvmonitor.app.data.UVReadingEntity
import com.uvmonitor.app.model.UVForecast
import com.uvmonitor.app.model.UVForecastPoint
import com.uvmonitor.app.model.UVStation
import com.uvmonitor.app.service.ARPANSAService
import com.uvmonitor.app.service.OpenMeteoService
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import java.util.Calendar
import java.util.Date
import java.util.TimeZone

class UVDataManager(application: Application) : AndroidViewModel(application) {

    private val prefs = application.getSharedPreferences("uv_monitor", Context.MODE_PRIVATE)
    private val db = AppDatabase.getInstance(application)
    private val dao = db.uvDao()
    private val arpansaService = ARPANSAService()
    private val openMeteoService = OpenMeteoService()

    private val _selectedStation = MutableStateFlow(loadStation())
    val selectedStation: StateFlow<UVStation> = _selectedStation.asStateFlow()

    private val _currentUV = MutableStateFlow<Double?>(null)
    val currentUV: StateFlow<Double?> = _currentUV.asStateFlow()

    private val _forecast = MutableStateFlow<UVForecast?>(null)
    val forecast: StateFlow<UVForecast?> = _forecast.asStateFlow()

    private val _measuredReadings = MutableStateFlow<List<UVForecastPoint>>(emptyList())
    val measuredReadings: StateFlow<List<UVForecastPoint>> = _measuredReadings.asStateFlow()

    private val _lastUpdated = MutableStateFlow<Date?>(null)
    val lastUpdated: StateFlow<Date?> = _lastUpdated.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()

    private val _viewingDate = MutableStateFlow(todayDateMillis())
    val viewingDate: StateFlow<Long> = _viewingDate.asStateFlow()

    private var pollingJob: Job? = null

    val isViewingToday: Boolean
        get() = _viewingDate.value == todayDateMillis()

    val isViewingTodayFlow = _viewingDate.map { it == todayDateMillis() }

    init {
        refreshData()
        startPolling()
        cleanOldData()
    }

    fun selectStation(station: UVStation) {
        _selectedStation.value = station
        prefs.edit().putString("station", station.name).apply()
        _currentUV.value = null
        _forecast.value = null
        _measuredReadings.value = emptyList()
        _viewingDate.value = todayDateMillis()
        refreshData()
    }

    fun refreshData() {
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null

            if (isViewingToday) {
                fetchLiveData()
            } else {
                loadHistoricalData()
            }

            _isLoading.value = false
        }
    }

    fun navigateDay(offset: Int) {
        val cal = Calendar.getInstance(selectedStation.value.timeZone)
        cal.timeInMillis = _viewingDate.value
        cal.add(Calendar.DAY_OF_YEAR, offset)

        val today = todayDateMillis()
        if (cal.timeInMillis > today) return

        val thirtyDaysAgo = Calendar.getInstance(selectedStation.value.timeZone).apply {
            timeInMillis = today
            add(Calendar.DAY_OF_YEAR, -30)
        }.timeInMillis

        if (cal.timeInMillis < thirtyDaysAgo) return

        _viewingDate.value = normalizeToDay(cal.timeInMillis, selectedStation.value.timeZone)
        refreshData()
    }

    fun backToToday() {
        _viewingDate.value = todayDateMillis()
        refreshData()
    }

    private suspend fun fetchLiveData() {
        val station = _selectedStation.value
        try {
            // Fetch ARPANSA current reading and Open-Meteo forecast concurrently
            val arpansaJob = viewModelScope.launch {
                val reading = arpansaService.fetchCurrentUV(station)
                if (reading != null) {
                    _currentUV.value = reading.uvIndex
                    _lastUpdated.value = reading.dateTime ?: Date()

                    // Store reading
                    dao.insertReading(
                        UVReadingEntity(
                            stationId = station.code,
                            uvIndex = reading.uvIndex,
                            timestamp = System.currentTimeMillis()
                        )
                    )
                }
            }

            val forecastJob = viewModelScope.launch {
                val forecast = openMeteoService.fetchForecast(station)
                if (forecast != null) {
                    _forecast.value = forecast

                    // Store forecast
                    val dateMillis = todayDateMillis()
                    dao.insertForecast(
                        StoredForecastEntity.from(station.code, dateMillis, forecast)
                    )
                }
            }

            arpansaJob.join()
            forecastJob.join()

            // Load today's measured readings from DB
            loadMeasuredReadingsForDay(station, todayDateMillis())

        } catch (e: Exception) {
            _errorMessage.value = "Failed to fetch UV data"
        }
    }

    private suspend fun loadHistoricalData() {
        val station = _selectedStation.value
        val dateMillis = _viewingDate.value

        // Load stored forecast
        val storedForecast = dao.getForecast(station.code, dateMillis)
        _forecast.value = storedForecast?.toUVForecast()

        // Load stored readings
        loadMeasuredReadingsForDay(station, dateMillis)

        _currentUV.value = _measuredReadings.value.lastOrNull()?.uvIndex

        if (_forecast.value == null && _measuredReadings.value.isEmpty()) {
            _errorMessage.value = "No data available for this day"
        }
    }

    private suspend fun loadMeasuredReadingsForDay(station: UVStation, dateMillis: Long) {
        val cal = Calendar.getInstance(station.timeZone)
        cal.timeInMillis = dateMillis
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        val dayStart = cal.timeInMillis

        cal.add(Calendar.DAY_OF_YEAR, 1)
        val dayEnd = cal.timeInMillis

        val readings = dao.getReadingsForDay(station.code, dayStart, dayEnd)
        _measuredReadings.value = readings.map {
            UVForecastPoint(Date(it.timestamp), it.uvIndex)
        }
    }

    private fun startPolling() {
        pollingJob?.cancel()
        pollingJob = viewModelScope.launch {
            while (true) {
                delay(5 * 60 * 1000L) // 5 minutes
                if (isViewingToday) {
                    fetchLiveData()
                }
            }
        }
    }

    private fun cleanOldData() {
        viewModelScope.launch {
            val thirtyDaysAgo = System.currentTimeMillis() - (30L * 24 * 60 * 60 * 1000)
            dao.deleteOldReadings(thirtyDaysAgo)
            dao.deleteOldForecasts(thirtyDaysAgo)
        }
    }

    private fun loadStation(): UVStation {
        val name = prefs.getString("station", null) ?: return UVStation.SYDNEY
        return try {
            UVStation.valueOf(name)
        } catch (e: IllegalArgumentException) {
            UVStation.SYDNEY
        }
    }

    private fun todayDateMillis(): Long {
        return normalizeToDay(System.currentTimeMillis(), _selectedStation.value.timeZone)
    }

    private fun normalizeToDay(millis: Long, tz: TimeZone): Long {
        val cal = Calendar.getInstance(tz)
        cal.timeInMillis = millis
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        return cal.timeInMillis
    }
}
