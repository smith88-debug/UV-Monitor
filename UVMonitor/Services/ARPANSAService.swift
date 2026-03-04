import Foundation

struct ARPANSAReading {
    let stationName: String
    let uvIndex: Double
    let localTime: String
    let date: String
    let utcDateTime: String
    let status: String
}

actor ARPANSAService {
    private let url = URL(string: "https://uvdata.arpansa.gov.au/xml/uvvalues.xml")!

    func fetchCurrentReadings() async throws -> [String: ARPANSAReading] {
        let (data, _) = try await URLSession.shared.data(from: url)
        let parser = ARPANSAXMLParser(data: data)
        return parser.parse()
    }

    func fetchReading(for station: UVStation) async throws -> ARPANSAReading? {
        let readings = try await fetchCurrentReadings()
        return readings[station.rawValue]
    }
}

private final class ARPANSAXMLParser: NSObject, XMLParserDelegate {
    private let data: Data
    private var readings: [String: ARPANSAReading] = [:]

    private var currentLocationId = ""
    private var currentElement = ""
    private var currentName = ""
    private var currentIndex = ""
    private var currentTime = ""
    private var currentDate = ""
    private var currentUtcDateTime = ""
    private var currentStatus = ""

    init(data: Data) {
        self.data = data
    }

    func parse() -> [String: ARPANSAReading] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return readings
    }

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
