import UserNotifications

enum NotificationService {
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func scheduleReminder(for schedule: Schedule) {
        guard let minutes = schedule.reminderMinutes else { return }
        let triggerDate = schedule.startDate.addingTimeInterval(-Double(minutes * 60))
        guard triggerDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "일정 알림"
        content.body = "[\(schedule.category.rawValue)] \(schedule.title)"
        if minutes >= 60 {
            content.subtitle = "\(minutes / 60)시간 후 시작"
        } else {
            content.subtitle = "\(minutes)분 후 시작"
        }
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: schedule.id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func cancelReminder(for scheduleId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [scheduleId])
    }
}
