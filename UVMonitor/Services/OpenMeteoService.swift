import Foundation
import CoreLocation

actor OpenMeteoService {
    func fetchForecast(for coordinate: CLLocationCoordinate2D) async throws -> UVForecast {
        let urlString = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=\(coordinate.latitude)"
            + "&longitude=\(coordinate.longitude)"
            + "&hourly=uv_index"
            + "&timezone=auto"
            + "&forecast_days=1"

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)

        let iso8601 = ISO8601DateFormatter()
        iso8601.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let fallbackFormatter = DateFormatter()
        fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        fallbackFormatter.timeZone = TimeZone(identifier: response.timezone)

        var points: [UVForecastPoint] = []
        for (timeStr, uvIndex) in zip(response.hourly.time, response.hourly.uvIndex) {
            if let date = iso8601.date(from: timeStr) ?? fallbackFormatter.date(from: timeStr) {
                points.append(UVForecastPoint(time: date, uvIndex: uvIndex))
            }
        }

        return UVForecast(points: points)
    }
}

private struct OpenMeteoResponse: Decodable {
    let timezone: String
    let hourly: HourlyData

    struct HourlyData: Decodable {
        let time: [String]
        let uvIndex: [Double]

        enum CodingKeys: String, CodingKey {
            case time
            case uvIndex = "uv_index"
        }
    }
}
