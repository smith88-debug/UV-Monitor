import Foundation

struct ARPANSAReading {
    let stationName: String
    let uvIndex: Double
    let localTime: String
    let date: String
    let utcDateTime: String
    let status: String

    /// Parses the ARPANSA utcDateTime string into a Date.
    /// Tries common ARPANSA formats: "yyyy-MM-dd'T'HH:mm:ss", "yyyy-MM-dd HH:mm:ss",
    /// "dd MMM yyyy HH:mm:ss", and ISO 8601 with 'Z' suffix.
    var parsedTimestamp: Date? {
        let trimmed = utcDateTime.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Try ISO 8601 with Z suffix first (e.g. "2026-03-06T05:53:00Z")
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        if let d = iso.date(from: trimmed) { return d }

        // Common ARPANSA formats (all interpreted as UTC)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")

        for fmt in [
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd HH:mm",
            "dd MMM yyyy HH:mm:ss",
            "dd/MM/yyyy HH:mm:ss",
        ] {
            formatter.dateFormat = fmt
            if let d = formatter.date(from: trimmed) { return d }
        }
        return nil
    }
}

actor ARPANSAService {
    private let url = URL(string: "https://uvdata.arpansa.gov.au/xml/uvvalues.xml")!

    func fetchCurrentReadings() async throws -> [String: ARPANSAReading] {
        let (data, _) = try await URLSession.shared.data(from: url)
        return ARPANSAXMLParser.parse(data: data)
    }

    func fetchReading(for station: UVStation) async throws -> ARPANSAReading? {
        let readings = try await fetchCurrentReadings()
        return readings[station.rawValue]
    }
}

enum ARPANSAXMLParser {
    static func parse(data: Data) -> [String: ARPANSAReading] {
        let delegate = ParserDelegate()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.parse()
        return delegate.readings
    }
}

private final class ParserDelegate: NSObject, XMLParserDelegate {
    var readings: [String: ARPANSAReading] = [:]

    private var currentLocationId = ""
    private var currentElement = ""
    private var currentName = ""
    private var currentIndex = ""
    private var currentTime = ""
    private var currentDate = ""
    private var currentUtcDateTime = ""
    private var currentStatus = ""

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName: String?,
                attributes: [String: String] = [:]) {
        currentElement = elementName
        if elementName == "location" {
            currentLocationId = attributes["id"] ?? ""
            currentName = ""
            currentIndex = ""
            currentTime = ""
            currentDate = ""
            currentUtcDateTime = ""
            currentStatus = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        switch currentElement {
        case "name": currentName += trimmed
        case "index": currentIndex += trimmed
        case "time": currentTime += trimmed
        case "date": currentDate += trimmed
        case "utcdatetime": currentUtcDateTime += trimmed
        case "status": currentStatus += trimmed
        default: break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName: String?) {
        if elementName == "location" {
            let reading = ARPANSAReading(
                stationName: currentLocationId,
                uvIndex: Double(currentIndex) ?? 0,
                localTime: currentTime,
                date: currentDate,
                utcDateTime: currentUtcDateTime,
                status: currentStatus
            )
            readings[currentLocationId] = reading
        }
        currentElement = ""
    }
}
