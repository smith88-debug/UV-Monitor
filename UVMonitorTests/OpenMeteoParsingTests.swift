import Testing
import Foundation
@testable import UVMonitor

@Suite("Open-Meteo Response Parsing")
struct OpenMeteoParsingTests {

    private let sampleJSON = """
    {
        "timezone": "Australia/Sydney",
        "hourly": {
            "time": [
                "2026-03-05T00:00",
                "2026-03-05T06:00",
                "2026-03-05T09:00",
                "2026-03-05T12:00",
                "2026-03-05T15:00",
                "2026-03-05T18:00"
            ],
            "uv_index": [0.0, 0.5, 3.2, 8.7, 5.1, 0.2]
        }
    }
    """

    @Test("Decodes valid JSON response")
    func decodesResponse() throws {
        let data = Data(sampleJSON.utf8)
        let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        #expect(response.timezone == "Australia/Sydney")
        #expect(response.hourly.time.count == 6)
        #expect(response.hourly.uvIndex.count == 6)
    }

    @Test("UV index values match expected")
    func uvIndexValues() throws {
        let data = Data(sampleJSON.utf8)
        let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        #expect(response.hourly.uvIndex[0] == 0.0)
        #expect(response.hourly.uvIndex[3] == 8.7)
    }

    @Test("Time strings are correctly formatted")
    func timeStrings() throws {
        let data = Data(sampleJSON.utf8)
        let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        #expect(response.hourly.time[0] == "2026-03-05T00:00")
        #expect(response.hourly.time[3] == "2026-03-05T12:00")
    }

    @Test("Throws on invalid JSON")
    func invalidJSON() {
        let data = Data("{ invalid }".utf8)
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        }
    }

    @Test("Throws on missing uv_index field")
    func missingField() {
        let json = """
        {
            "timezone": "Australia/Sydney",
            "hourly": { "time": ["2026-03-05T00:00"] }
        }
        """
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(OpenMeteoResponse.self, from: Data(json.utf8))
        }
    }
}
