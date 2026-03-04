import SwiftUI
import SwiftData
import BackgroundTasks

@main
struct UVMonitorApp: App {
    private let container: ModelContainer
    @State private var dataManager = UVDataManager()

    init() {
        do {
            container = try ModelContainer(for: UVReading.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            DashboardView(dataManager: dataManager)
                .modelContainer(container)
                .onAppear {
                    dataManager.configure(modelContext: container.mainContext)
                    dataManager.startPolling()
                    dataManager.cleanOldReadings()
                    UVNotificationManager.requestPermission()
                    registerBackgroundRefresh()
                }
                .onChange(of: dataManager.forecast) {
                    if let forecast = dataManager.forecast {
                        UVNotificationManager.scheduleProtectionAlerts(from: forecast)
                    }
                }
        }
    }

    private func registerBackgroundRefresh() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.uvmonitor.app.uvrefresh",
            using: nil
        ) { task in
            handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }
        scheduleBackgroundRefresh()
    }

    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        task.expirationHandler = { task.setTaskCompleted(success: false) }

        Task { @MainActor in
            await dataManager.refresh()
            task.setTaskCompleted(success: true)
            scheduleBackgroundRefresh()
        }
    }

    private func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.uvmonitor.app.uvrefresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }
}
