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

                    // Date navigation
                    dateNavigationBar

                    // UV Index card
                    UVIndexCard(
                        uvIndex: dataManager.isViewingToday ? dataManager.currentUV : dataManager.displayedPeakUV,
                        level: dataManager.isViewingToday ? dataManager.currentLevel : dataManager.displayedPeakLevel,
                        lastUpdated: dataManager.isViewingToday ? dataManager.lastUpdated : nil
                    )

                    // Protection banner
                    ProtectionBanner(
                        level: dataManager.isViewingToday ? dataManager.currentLevel : dataManager.displayedPeakLevel,
                        protectionStart: dataManager.displayedProtectionStart,
                        protectionEnd: dataManager.displayedProtectionEnd
                    )

                    // Combined chart
                    UVChartView(
                        forecast: dataManager.displayedForecast,
                        measured: dataManager.displayedReadings,
                        stationTimeZone: dataManager.selectedStation.timeZone,
                        date: dataManager.selectedDate,
                        isToday: dataManager.isViewingToday
                    )

                    // Peak UV info
                    if dataManager.displayedPeakUV > 0 {
                        HStack {
                            Label("Peak forecast: \(String(format: "%.1f", dataManager.displayedPeakUV))",
                                  systemImage: "sun.max.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }

                    // No data message for historical days
                    if !dataManager.isViewingToday && dataManager.displayedReadings.isEmpty && dataManager.displayedForecast == nil {
                        Text("No data available for this day")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding()
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
                if dataManager.isViewingToday {
                    await dataManager.refresh()
                }
            }
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView(selectedStation: $dataManager.selectedStation)
            }
        }
    }

    private var dateNavigationBar: some View {
        HStack {
            Button { dataManager.goToPreviousDay() } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(dateHeaderString)
                    .font(.headline)
                if !dataManager.isViewingToday {
                    Button("Back to Today") { dataManager.goToToday() }
                        .font(.caption)
                }
            }

            Spacer()

            Button { dataManager.goToNextDay() } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .disabled(dataManager.isViewingToday)
        }
        .padding(.horizontal)
    }

    private var dateHeaderString: String {
        if dataManager.isViewingToday { return "Today" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d MMM"
        formatter.timeZone = dataManager.selectedStation.timeZone
        return formatter.string(from: dataManager.selectedDate)
    }
}
