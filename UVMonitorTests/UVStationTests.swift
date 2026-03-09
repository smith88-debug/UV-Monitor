import Testing
import CoreLocation
@testable import UVMonitor

@Suite("UV Station")
struct UVStationTests {

    @Test("All stations have unique codes")
    func uniqueCodes() {
        let codes = UVStation.allCases.map(\.code)
        #expect(Set(codes).count == codes.count)
    }

    @Test("All stations have 3-letter codes")
    func threeLetterCodes() {
        for station in UVStation.allCases {
            #expect(station.code.count == 3)
        }
    }

    @Test("Australian stations excludes Antarctic")
    func australianStationsOnly() {
        let aus = UVStation.australianStations
        #expect(!aus.contains(.casey))
        #expect(!aus.contains(.davis))
        #expect(!aus.contains(.mawson))
        #expect(!aus.contains(.macquarieIsland))
        #expect(aus.contains(.sydney))
        #expect(aus.contains(.melbourne))
    }

    @Test("Australian stations has 12 entries")
    func australianStationCount() {
        #expect(UVStation.australianStations.count == 12)
    }

    @Test("Nearest station to Sydney CBD returns Sydney")
    func nearestToSydneyCBD() {
        let sydneyCBD = CLLocation(latitude: -33.8688, longitude: 151.2093)
        #expect(UVStation.nearest(to: sydneyCBD) == .sydney)
    }

    @Test("Nearest station to Melbourne CBD returns Melbourne")
    func nearestToMelbourneCBD() {
        let melbourneCBD = CLLocation(latitude: -37.8136, longitude: 144.9631)
        #expect(UVStation.nearest(to: melbourneCBD) == .melbourne)
    }

    @Test("Nearest station to Perth returns Perth")
    func nearestToPerth() {
        let perth = CLLocation(latitude: -31.95, longitude: 115.86)
        #expect(UVStation.nearest(to: perth) == .perth)
    }

    @Test("Nearest station to Wollongong returns Sydney (closest)")
    func nearestToWollongong() {
        let wollongong = CLLocation(latitude: -34.4278, longitude: 150.8931)
        #expect(UVStation.nearest(to: wollongong) == .sydney)
    }

    @Test("All coordinates are in valid ranges")
    func validCoordinates() {
        for station in UVStation.allCases {
            let coord = station.coordinate
            #expect(coord.latitude >= -90 && coord.latitude <= 90)
            #expect(coord.longitude >= -180 && coord.longitude <= 180)
        }
    }

    @Test("Station raw values match ARPANSA IDs")
    func rawValuesMatchARPANSA() {
        #expect(UVStation.sydney.rawValue == "Sydney")
        #expect(UVStation.aliceSprings.rawValue == "Alice Springs")
        #expect(UVStation.goldCoast.rawValue == "Gold Coast")
    }
}
