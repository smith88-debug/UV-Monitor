import Foundation
import CoreLocation

enum UVStation: String, CaseIterable, Identifiable, Codable {
    case adelaide = "Adelaide"
    case aliceSprings = "Alice Springs"
    case brisbane = "Brisbane"
    case canberra = "Canberra"
    case casey = "Casey"
    case darwin = "Darwin"
    case davis = "Davis"
    case emerald = "Emerald"
    case goldCoast = "Gold Coast"
    case kingston = "Kingston"
    case macquarieIsland = "Macquarie Island"
    case mawson = "Mawson"
    case melbourne = "Melbourne"
    case newcastle = "Newcastle"
    case perth = "Perth"
    case sydney = "Sydney"
    case townsville = "Townsville"

    var id: String { rawValue }

    var code: String {
        switch self {
        case .adelaide: "adl"
        case .aliceSprings: "ali"
        case .brisbane: "bri"
        case .canberra: "can"
        case .casey: "cas"
        case .darwin: "dar"
        case .davis: "dav"
        case .emerald: "eme"
        case .goldCoast: "gol"
        case .kingston: "kin"
        case .macquarieIsland: "mac"
        case .mawson: "maw"
        case .melbourne: "mel"
        case .newcastle: "new"
        case .perth: "per"
        case .sydney: "syd"
        case .townsville: "tow"
        }
    }

    var coordinate: CLLocationCoordinate2D {
        switch self {
        case .adelaide:         CLLocationCoordinate2D(latitude: -34.9285, longitude: 138.6007)
        case .aliceSprings:     CLLocationCoordinate2D(latitude: -23.6980, longitude: 133.8807)
        case .brisbane:         CLLocationCoordinate2D(latitude: -27.4698, longitude: 153.0251)
        case .canberra:         CLLocationCoordinate2D(latitude: -35.2809, longitude: 149.1300)
        case .casey:            CLLocationCoordinate2D(latitude: -66.2823, longitude: 110.5278)
        case .darwin:           CLLocationCoordinate2D(latitude: -12.4634, longitude: 130.8456)
        case .davis:            CLLocationCoordinate2D(latitude: -68.5772, longitude: 77.9696)
        case .emerald:          CLLocationCoordinate2D(latitude: -23.5275, longitude: 148.1603)
        case .goldCoast:        CLLocationCoordinate2D(latitude: -28.0167, longitude: 153.4000)
        case .kingston:         CLLocationCoordinate2D(latitude: -42.9884, longitude: 147.3311)
        case .macquarieIsland:  CLLocationCoordinate2D(latitude: -54.6208, longitude: 158.8556)
        case .mawson:           CLLocationCoordinate2D(latitude: -67.6027, longitude: 62.8738)
        case .melbourne:        CLLocationCoordinate2D(latitude: -37.8136, longitude: 144.9631)
        case .newcastle:        CLLocationCoordinate2D(latitude: -32.9283, longitude: 151.7817)
        case .perth:            CLLocationCoordinate2D(latitude: -31.9505, longitude: 115.8605)
        case .sydney:           CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093)
        case .townsville:       CLLocationCoordinate2D(latitude: -19.2590, longitude: 146.8169)
        }
    }

    var timeZone: TimeZone {
        switch self {
        case .perth:
            TimeZone(identifier: "Australia/Perth")!
        case .darwin:
            TimeZone(identifier: "Australia/Darwin")!
        case .adelaide:
            TimeZone(identifier: "Australia/Adelaide")!
        case .brisbane, .goldCoast, .emerald, .townsville:
            TimeZone(identifier: "Australia/Brisbane")!
        case .sydney, .canberra, .newcastle:
            TimeZone(identifier: "Australia/Sydney")!
        case .melbourne:
            TimeZone(identifier: "Australia/Melbourne")!
        case .kingston:
            TimeZone(identifier: "Australia/Hobart")!
        case .aliceSprings:
            TimeZone(identifier: "Australia/Darwin")!
        case .casey, .davis, .mawson, .macquarieIsland:
            // Antarctic stations – use UTC as a sensible default
            TimeZone(identifier: "UTC")!
        }
    }

    /// Australian mainland/city stations (excludes Antarctic research stations)
    static var australianStations: [UVStation] {
        [.adelaide, .aliceSprings, .brisbane, .canberra, .darwin, .emerald,
         .goldCoast, .melbourne, .newcastle, .perth, .sydney, .townsville]
    }

    static func nearest(to location: CLLocation) -> UVStation {
        australianStations.min { a, b in
            let distA = location.distance(from: CLLocation(latitude: a.coordinate.latitude, longitude: a.coordinate.longitude))
            let distB = location.distance(from: CLLocation(latitude: b.coordinate.latitude, longitude: b.coordinate.longitude))
            return distA < distB
        } ?? .sydney
    }
}
