import Testing
import Foundation
@testable import UVMonitor

@Suite("UV Forecast")
struct UVForecastTests {

    private func makePoint(hour: Int, uvIndex: Double) -> UVForecastPoint {
        let date = Calendar.current.date(
            bySettingHour: hour, minute: 0, second: 0,
            of: Date()
        )!
        return UVForecastPoint(time: date, uvIndex: uvIndex)
    }

    @Test("Peak UV returns highest value")
    func peakUV() {
        let forecast = UVForecast(points: [
            makePoint(hour: 6, uvIndex: 1.0),
            makePoint(hour: 10, uvIndex: 5.0),
            makePoint(hour: 12, uvIndex: 9.5),
            makePoint(hour: 14, uvIndex: 7.0),
            makePoint(hour: 18, uvIndex: 0.5),
        ])
        #expect(forecast.peakUV == 9.5)
    }

    @Test("Peak UV returns 0 for empty forecast")
    func peakUVEmpty() {
        let forecast = UVForecast(points: [])
        #expect(forecast.peakUV == 0)
    }

    @Test("Protection start time is first point >= 3")
    func protectionStartTime() {
        let points = [
            makePoint(hour: 6, uvIndex: 1.0),
            makePoint(hour: 8, uvIndex: 2.5),
            makePoint(hour: 9, uvIndex: 3.2),
            makePoint(hour: 12, uvIndex: 8.0),
        ]
        let forecast = UVForecast(points: points)
        let startHour = Calendar.current.component(.hour, from: forecast.protectionStartTime!)
        #expect(startHour == 9)
    }

    @Test("Protection end time is last point >= 3")
    func protectionEndTime() {
        let points = [
            makePoint(hour: 9, uvIndex: 3.2),
            makePoint(hour: 12, uvIndex: 8.0),
            makePoint(hour: 15, uvIndex: 4.0),
            makePoint(hour: 16, uvIndex: 2.5),
        ]
        let forecast = UVForecast(points: points)
        let endHour = Calendar.current.component(.hour, from: forecast.protectionEndTime!)
        #expect(endHour == 15)
    }

    @Test("Protection times nil when UV never reaches 3")
    func noProtectionNeeded() {
        let forecast = UVForecast(points: [
            makePoint(hour: 8, uvIndex: 1.0),
            makePoint(hour: 12, uvIndex: 2.5),
        ])
        #expect(forecast.protectionStartTime == nil)
        #expect(forecast.protectionEndTime == nil)
    }
}
