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

        // Open-Meteo returns local timestamps like "2026-03-06T12:00" (no TZ suffix)
        // when timezone=auto is used. Parse them in the station's timezone.
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: response.timezone)

        var points: [UVForecastPoint] = []
        for (timeStr, uvIndex) in zip(response.hourly.time, response.hourly.uvIndex) {
            if let date = formatter.date(from: timeStr) {
                points.append(UVForecastPoint(time: date, uvIndex: uvIndex))
            }
        }

        return UVForecast(points: points)
    }
}

struct OpenMeteoResponse: Decodable {
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
