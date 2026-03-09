import Testing
import Foundation
@testable import UVMonitor

@Suite("ARPANSA XML Parser")
struct ARPANSAParserTests {

    private let sampleXML = """
    <?xml version="1.0" encoding="utf-8"?>
    <stations>
      <location id="Sydney">
        <name>syd</name>
        <index>6.2</index>
        <time>1:35 PM</time>
        <date>5/03/2026</date>
        <fulldate>Thursday, 5 March 2026</fulldate>
        <utcdatetime>2026/03/05 02:35</utcdatetime>
        <status>ok</status>
      </location>
      <location id="Melbourne">
        <name>mel</name>
        <index>4.1</index>
        <time>1:35 PM</time>
        <date>5/03/2026</date>
        <fulldate>Thursday, 5 March 2026</fulldate>
        <utcdatetime>2026/03/05 02:35</utcdatetime>
        <status>ok</status>
      </location>
      <location id="Darwin">
        <name>dar</name>
        <index>0.0</index>
        <time>1:05 PM</time>
        <date>5/03/2026</date>
        <fulldate>Thursday, 5 March 2026</fulldate>
        <utcdatetime>2026/03/05 03:35</utcdatetime>
        <status>na</status>
      </location>
    </stations>
    """

    @Test("Parses all stations from XML")
    func parsesAllStations() {
        let data = Data(sampleXML.utf8)
        let readings = ARPANSAXMLParser.parse(data: data)
        #expect(readings.count == 3)
    }

    @Test("Parses station name correctly")
    func parsesStationName() {
        let data = Data(sampleXML.utf8)
        let readings = ARPANSAXMLParser.parse(data: data)
        #expect(readings["Sydney"]?.stationName == "Sydney")
        #expect(readings["Melbourne"]?.stationName == "Melbourne")
    }

    @Test("Parses UV index as Double")
    func parsesUVIndex() {
        let data = Data(sampleXML.utf8)
        let readings = ARPANSAXMLParser.parse(data: data)
        #expect(readings["Sydney"]?.uvIndex == 6.2)
        #expect(readings["Melbourne"]?.uvIndex == 4.1)
        #expect(readings["Darwin"]?.uvIndex == 0.0)
    }

    @Test("Parses status field")
    func parsesStatus() {
        let data = Data(sampleXML.utf8)
        let readings = ARPANSAXMLParser.parse(data: data)
        #expect(readings["Sydney"]?.status == "ok")
        #expect(readings["Darwin"]?.status == "na")
    }

    @Test("Parses time fields")
    func parsesTimeFields() {
        let data = Data(sampleXML.utf8)
        let readings = ARPANSAXMLParser.parse(data: data)
        #expect(readings["Sydney"]?.localTime == "1:35 PM")
        #expect(readings["Sydney"]?.date == "5/03/2026")
        #expect(readings["Sydney"]?.utcDateTime == "2026/03/05 02:35")
    }

    @Test("Returns empty for empty XML")
    func emptyXML() {
        let data = Data("<?xml version=\"1.0\"?><stations></stations>".utf8)
        let readings = ARPANSAXMLParser.parse(data: data)
        #expect(readings.isEmpty)
    }

    @Test("Returns empty for malformed XML")
    func malformedXML() {
        let data = Data("not xml at all".utf8)
        let readings = ARPANSAXMLParser.parse(data: data)
        #expect(readings.isEmpty)
    }

    @Test("Station lookup by UVStation rawValue works")
    func stationLookup() {
        let data = Data(sampleXML.utf8)
        let readings = ARPANSAXMLParser.parse(data: data)
        #expect(readings[UVStation.sydney.rawValue] != nil)
        #expect(readings[UVStation.melbourne.rawValue] != nil)
        #expect(readings[UVStation.perth.rawValue] == nil)
    }
}
