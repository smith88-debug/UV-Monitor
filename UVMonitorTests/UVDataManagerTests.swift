import Testing
import Foundation
@testable import UVMonitor

@Suite("UV Data Manager")
struct UVDataManagerTests {

    @Test("Default station is Sydney")
    @MainActor
    func defaultStation() {
        UserDefaults.standard.removeObject(forKey: "selectedStation")
        let manager = UVDataManager()
        #expect(manager.selectedStation == .sydney)
    }

    @Test("Restores saved station from UserDefaults")
    @MainActor
    func restoresSavedStation() {
        UserDefaults.standard.set("Melbourne", forKey: "selectedStation")
        let manager = UVDataManager()
        #expect(manager.selectedStation == .melbourne)
        UserDefaults.standard.removeObject(forKey: "selectedStation")
    }

    @Test("Changing station persists to UserDefaults")
    @MainActor
    func persistsStation() {
        let manager = UVDataManager()
        manager.selectedStation = .brisbane
        let saved = UserDefaults.standard.string(forKey: "selectedStation")
        #expect(saved == "Brisbane")
        UserDefaults.standard.removeObject(forKey: "selectedStation")
    }

    @Test("Initial state has zero UV and low level")
    @MainActor
    func initialState() {
        let manager = UVDataManager()
        #expect(manager.currentUV == 0)
        #expect(manager.currentLevel == .low)
        #expect(manager.lastUpdated == nil)
        #expect(manager.forecast == nil)
        #expect(manager.todayReadings.isEmpty)
        #expect(manager.isLoading == false)
        #expect(manager.errorMessage == nil)
    }
}
