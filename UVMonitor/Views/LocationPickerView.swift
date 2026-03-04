import SwiftUI
import CoreLocation

struct LocationPickerView: View {
    @Binding var selectedStation: UVStation
    @Environment(\.dismiss) private var dismiss
    @State private var locationManager = LocationHelper()

    var body: some View {
        NavigationStack {
            List {
                if let nearest = locationManager.nearestStation {
                    Section("Nearest to You") {
                        stationRow(nearest, isNearest: true)
                    }
                }

                Section("Australian Cities") {
                    ForEach(UVStation.australianStations) { station in
                        stationRow(station, isNearest: false)
                    }
                }

                Section("Research Stations") {
                    ForEach([UVStation.casey, .davis, .kingston, .macquarieIsland, .mawson]) { station in
                        stationRow(station, isNearest: false)
                    }
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            locationManager.requestLocation()
        }
    }

    private func stationRow(_ station: UVStation, isNearest: Bool) -> some View {
        Button {
            selectedStation = station
            dismiss()
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(station.rawValue)
                        .foregroundStyle(.primary)
                    if isNearest {
                        Text("Based on your location")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if station == selectedStation {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                }
            }
        }
    }
}

@Observable
private final class LocationHelper: NSObject, CLLocationManagerDelegate {
    var nearestStation: UVStation?
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            nearestStation = UVStation.nearest(to: location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Location unavailable — user can pick manually
    }
}
