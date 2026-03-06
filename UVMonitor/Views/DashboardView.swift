import SwiftUI

struct DashboardView: View {
    @Bindable var dataManager: UVDataManager
    @State private var showLocationPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Station header
                    Button {
                        showLocationPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.blue)
                            Text(dataManager.selectedStation.rawValue)
                                .fontWeight(.medium)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .foregroundStyle(.primary)
                    }

                    // UV Index card
                    UVIndexCard(
                        uvIndex: dataManager.currentUV,
                        level: dataManager.currentLevel,
                        lastUpdated: dataManager.lastUpdated
                    )

                    // Protection banner
                    ProtectionBanner(
                        level: dataManager.currentLevel,
                        protectionStart: dataManager.forecast?.protectionStartTime,
                        protectionEnd: dataManager.forecast?.protectionEndTime
                    )

                    // Combined chart
                    UVChartView(
                        forecast: dataManager.forecast,
                        measured: dataManager.todayReadings,
                        stationTimeZone: dataManager.selectedStation.timeZone
                    )

                    // Peak UV info
                    if let forecast = dataManager.forecast, forecast.peakUV > 0 {
                        HStack {
                            Label("Peak forecast: \(String(format: "%.1f", forecast.peakUV))",
                                  systemImage: "sun.max.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }

                    if let error = dataManager.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("UV Monitor")
            .refreshable {
                await dataManager.refresh()
            }
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView(selectedStation: $dataManager.selectedStation)
            }
        }
    }
}
