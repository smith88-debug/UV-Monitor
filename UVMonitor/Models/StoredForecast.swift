import Foundation
import SwiftData

@Model
final class StoredForecast {
    var stationId: String
    var date: Date
    var pointsData: Data

    init(stationId: String, date: Date, pointsData: Data) {
        self.stationId = stationId
        self.date = date
        self.pointsData = pointsData
    }

    static func encode(_ points: [UVForecastPoint]) -> Data {
        (try? JSONEncoder().encode(points)) ?? Data()
    }

    func toUVForecast() -> UVForecast? {
        guard let points = try? JSONDecoder().decode([UVForecastPoint].self, from: pointsData),
              !points.isEmpty else { return nil }
        return UVForecast(points: points)
    }
}
