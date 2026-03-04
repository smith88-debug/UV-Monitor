import Foundation
import SwiftData

@Model
final class UVReading {
    var stationId: String
    var uvIndex: Double
    var timestamp: Date

    init(stationId: String, uvIndex: Double, timestamp: Date) {
        self.stationId = stationId
        self.uvIndex = uvIndex
        self.timestamp = timestamp
    }
}
