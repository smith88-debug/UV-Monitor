import Foundation
import UserNotifications

struct UVNotificationManager {
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func scheduleProtectionAlerts(from forecast: UVForecast, stationTimeZone: TimeZone) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["uv-moderate", "uv-high"])

        if let moderateTime = forecast.protectionStartTime {
            scheduleAlert(
                id: "uv-moderate",
                title: "UV Rising — Apply Sunscreen",
                body: "UV index is reaching Moderate levels. Time to apply sun protection.",
                at: moderateTime,
                timeZone: stationTimeZone
            )
        }

        if let highTime = forecast.points.first(where: { $0.uvIndex >= 6 })?.time {
            scheduleAlert(
                id: "uv-high",
                title: "High UV — Seek Shade",
                body: "UV index is reaching High levels. Wear sunscreen, hat, and sunglasses.",
                at: highTime,
                timeZone: stationTimeZone
            )
        }
    }

    private static func scheduleAlert(id: String, title: String, body: String, at date: Date, timeZone: TimeZone) {
        guard date > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var cal = Calendar.current
        cal.timeZone = timeZone
        let components = cal.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}
