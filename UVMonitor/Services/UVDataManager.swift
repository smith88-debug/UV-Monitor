import Foundation
import SwiftData
import Combine

@MainActor
@Observable
final class UVDataManager {
    var selectedStation: UVStation {
        didSet {
            UserDefaults.standard.set(selectedStation.rawValue, forKey: "selectedStation")
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
        isLoading = false
    }

    private func fetchCurrentUV() async {
        do {
            let reading = try await arpansaService.fetchReading(for: selectedStation)
            if let reading, reading.status.lowercased() == "ok" {
                currentUV = reading.uvIndex
                currentLevel = UVLevel(index: reading.uvIndex)
                lastUpdated = Date()
                storeReading(uvIndex: reading.uvIndex)
            }
        } catch {
            errorMessage = "Unable to fetch UV data"
        }
    }

    private func fetchForecast() async {
        do {
            forecast = try await openMeteoService.fetchForecast(for: selectedStation.coordinate)
        } catch {
            if errorMessage == nil {
                errorMessage = "Unable to fetch forecast"
            }
        }
    }

    private func storeReading(uvIndex: Double) {
        guard let modelContext else { return }
        let reading = UVReading(
            stationId: selectedStation.rawValue,
            uvIndex: uvIndex,
            timestamp: Date()
        )
        modelContext.insert(reading)
        try? modelContext.save()
    }

    private func loadTodayReadings() {
        guard let modelContext else { return }
        let stationId = selectedStation.rawValue
        let startOfDay = Calendar.current.startOfDay(for: Date())

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
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date()))!
        let descriptor = FetchDescriptor<UVReading>(
            predicate: #Predicate { reading in
                reading.timestamp < yesterday
            }
        )
        if let old = try? modelContext.fetch(descriptor) {
            for reading in old {
                modelContext.delete(reading)
            }
            try? modelContext.save()
        }
    }
}
