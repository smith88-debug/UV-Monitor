import Foundation
import SwiftData
import Combine

@MainActor
@Observable
final class UVDataManager {
    var selectedStation: UVStation {
        didSet {
            UserDefaults.standard.set(selectedStation.rawValue, forKey: "selectedStation")
            resetToToday()
            Task { await refresh() }
        }
    }

    var currentUV: Double = 0
    var currentLevel: UVLevel = .low
    var lastUpdated: Date?
    var forecast: UVForecast?
    var todayReadings: [UVForecastPoint] = []
    var isLoading = false
    var errorMessage: String?

    // Day history navigation
    var selectedDate: Date = Date()
    var displayedReadings: [UVForecastPoint] = []
    var displayedForecast: UVForecast?

    var isViewingToday: Bool {
        var cal = Calendar.current
        cal.timeZone = selectedStation.timeZone
        return cal.isDate(selectedDate, inSameDayAs: Date())
    }

    var displayedPeakUV: Double {
        if isViewingToday { return forecast?.peakUV ?? todayReadings.map(\.uvIndex).max() ?? 0 }
        let forecastPeak = displayedForecast?.peakUV ?? 0
        let measuredPeak = displayedReadings.map(\.uvIndex).max() ?? 0
        return max(forecastPeak, measuredPeak)
    }

    var displayedPeakLevel: UVLevel {
        UVLevel(index: displayedPeakUV)
    }

    var displayedProtectionStart: Date? {
        if isViewingToday { return forecast?.protectionStartTime }
        return displayedForecast?.protectionStartTime
    }

    var displayedProtectionEnd: Date? {
        if isViewingToday { return forecast?.protectionEndTime }
        return displayedForecast?.protectionEndTime
    }

    private let arpansaService = ARPANSAService()
    private let openMeteoService = OpenMeteoService()
    private var modelContext: ModelContext?
    private var pollTimer: Timer?

    init() {
        if let saved = UserDefaults.standard.string(forKey: "selectedStation"),
           let station = UVStation(rawValue: saved) {
            self.selectedStation = station
        } else {
            self.selectedStation = .sydney
        }
    }

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchCurrentUV()
            }
        }
        Task { await refresh() }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil

        async let uvTask: () = fetchCurrentUV()
        async let forecastTask: () = fetchForecast()

        await uvTask
        await forecastTask

        loadTodayReadings()
        storeForecastIfNeeded()
        loadDataForSelectedDate()
        isLoading = false
    }

    private func fetchCurrentUV() async {
        do {
            let reading = try await arpansaService.fetchReading(for: selectedStation)
            if let reading, reading.status.lowercased() == "ok" {
                currentUV = reading.uvIndex
                currentLevel = UVLevel(index: reading.uvIndex)
                lastUpdated = Date()
                // Use ARPANSA's reported measurement time, falling back to device time
                let measurementTime = reading.parsedTimestamp ?? Date()
                storeReading(uvIndex: reading.uvIndex, timestamp: measurementTime)
            }
        } catch {
            errorMessage = "UV fetch failed: \(error.localizedDescription)"
        }
    }

    private func fetchForecast() async {
        do {
            forecast = try await openMeteoService.fetchForecast(for: selectedStation.coordinate)
        } catch {
            if errorMessage == nil {
                errorMessage = "Forecast failed: \(error.localizedDescription)"
            }
        }
    }

    private func storeReading(uvIndex: Double, timestamp: Date) {
        guard let modelContext else { return }
        let reading = UVReading(
            stationId: selectedStation.rawValue,
            uvIndex: uvIndex,
            timestamp: timestamp
        )
        modelContext.insert(reading)
        try? modelContext.save()
    }

    private func loadTodayReadings() {
        guard let modelContext else { return }
        let stationId = selectedStation.rawValue
        var cal = Calendar.current
        cal.timeZone = selectedStation.timeZone
        let startOfDay = cal.startOfDay(for: Date())

        let descriptor = FetchDescriptor<UVReading>(
            predicate: #Predicate { reading in
                reading.stationId == stationId && reading.timestamp >= startOfDay
            },
            sortBy: [SortDescriptor(\.timestamp)]
        )

        if let readings = try? modelContext.fetch(descriptor) {
            todayReadings = readings.map {
                UVForecastPoint(time: $0.timestamp, uvIndex: $0.uvIndex)
            }
        }
    }

    func cleanOldReadings() {
        guard let modelContext else { return }
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Calendar.current.startOfDay(for: Date()))!

        let readingDescriptor = FetchDescriptor<UVReading>(
            predicate: #Predicate { reading in
                reading.timestamp < cutoff
            }
        )
        if let old = try? modelContext.fetch(readingDescriptor) {
            for reading in old { modelContext.delete(reading) }
        }

        let forecastDescriptor = FetchDescriptor<StoredForecast>(
            predicate: #Predicate { forecast in
                forecast.date < cutoff
            }
        )
        if let old = try? modelContext.fetch(forecastDescriptor) {
            for forecast in old { modelContext.delete(forecast) }
        }

        try? modelContext.save()
    }

    // MARK: - Day History Navigation

    func goToPreviousDay() {
        var cal = Calendar.current
        cal.timeZone = selectedStation.timeZone
        selectedDate = cal.date(byAdding: .day, value: -1, to: selectedDate)!
        loadDataForSelectedDate()
    }

    func goToNextDay() {
        var cal = Calendar.current
        cal.timeZone = selectedStation.timeZone
        let next = cal.date(byAdding: .day, value: 1, to: selectedDate)!
        let today = cal.startOfDay(for: Date())
        selectedDate = next > today ? today : next
        loadDataForSelectedDate()
    }

    func goToToday() {
        resetToToday()
        loadDataForSelectedDate()
    }

    private func resetToToday() {
        var cal = Calendar.current
        cal.timeZone = selectedStation.timeZone
        selectedDate = cal.startOfDay(for: Date())
    }

    func loadDataForSelectedDate() {
        guard let modelContext else { return }
        let stationId = selectedStation.rawValue
        var cal = Calendar.current
        cal.timeZone = selectedStation.timeZone
        let dayStart = cal.startOfDay(for: selectedDate)
        let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart)!

        // Load readings for the selected date
        let readingDescriptor = FetchDescriptor<UVReading>(
            predicate: #Predicate { reading in
                reading.stationId == stationId && reading.timestamp >= dayStart && reading.timestamp < dayEnd
            },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        if let readings = try? modelContext.fetch(readingDescriptor) {
            displayedReadings = readings.map {
                UVForecastPoint(time: $0.timestamp, uvIndex: $0.uvIndex)
            }
        } else {
            displayedReadings = []
        }

        // Load stored forecast for the selected date
        let forecastDescriptor = FetchDescriptor<StoredForecast>(
            predicate: #Predicate { forecast in
                forecast.stationId == stationId && forecast.date == dayStart
            }
        )
        if let stored = try? modelContext.fetch(forecastDescriptor).first {
            displayedForecast = stored.toUVForecast()
        } else if isViewingToday {
            displayedForecast = forecast
        } else {
            displayedForecast = nil
        }
    }

    private func storeForecastIfNeeded() {
        guard let modelContext, let forecast else { return }
        let stationId = selectedStation.rawValue
        var cal = Calendar.current
        cal.timeZone = selectedStation.timeZone
        let today = cal.startOfDay(for: Date())

        let descriptor = FetchDescriptor<StoredForecast>(
            predicate: #Predicate { stored in
                stored.stationId == stationId && stored.date == today
            }
        )
        if let existing = try? modelContext.fetch(descriptor), !existing.isEmpty { return }

        let stored = StoredForecast(
            stationId: stationId,
            date: today,
            pointsData: StoredForecast.encode(forecast.points)
        )
        modelContext.insert(stored)
        try? modelContext.save()
    }
}
