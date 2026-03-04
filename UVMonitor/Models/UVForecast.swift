import Foundation

struct UVForecastPoint: Identifiable, Equatable {
    let id = UUID()
    let time: Date
    let uvIndex: Double

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.time == rhs.time && lhs.uvIndex == rhs.uvIndex
    }
}

struct UVForecast: Equatable {
    let points: [UVForecastPoint]

    var peakUV: Double {
        points.map(\.uvIndex).max() ?? 0
    }

    var protectionStartTime: Date? {
        points.first { $0.uvIndex >= 3 }?.time
    }

    var protectionEndTime: Date? {
        points.last { $0.uvIndex >= 3 }?.time
    }
}
