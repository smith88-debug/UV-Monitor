import Foundation

struct UVForecastPoint: Identifiable, Equatable, Codable {
    let id: UUID
    let time: Date
    let uvIndex: Double

    init(time: Date, uvIndex: Double) {
        self.id = UUID()
        self.time = time
        self.uvIndex = uvIndex
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.time == rhs.time && lhs.uvIndex == rhs.uvIndex
    }

    enum CodingKeys: String, CodingKey {
        case time, uvIndex
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.time = try container.decode(Date.self, forKey: .time)
        self.uvIndex = try container.decode(Double.self, forKey: .uvIndex)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(time, forKey: .time)
        try container.encode(uvIndex, forKey: .uvIndex)
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
