import Foundation
import WidgetKit

enum WidgetService {
    private static let suiteName = "group.com.TaeYoungJin.FreelanceScheduler"

    static func updateWidget(schedules: [Schedule], accountBooks: [AccountBook]) {
        let today = Date()
        let todaySchedules = schedules
            .filter { $0.startDate.isSameDay(as: today) }
            .prefix(5)
            .map { schedule in
                WidgetScheduleItem(
                    id: schedule.id,
                    title: schedule.title,
                    category: schedule.category.rawValue,
                    time: formatTime(schedule.startDate),
                    colorHex: schedule.category.colorHex
                )
            }

        let now = Date()
        let monthBooks = accountBooks.filter { $0.date.year == now.year && $0.date.month == now.month }
        let income = monthBooks.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let expense = monthBooks.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }

        let data = WidgetData(
            todaySchedules: Array(todaySchedules),
            monthIncome: income,
            monthExpense: expense,
            monthName: "\(now.month)월"
        )

        if let encoded = try? JSONEncoder().encode(data),
           let defaults = UserDefaults(suiteName: suiteName) {
            defaults.set(encoded, forKey: "widgetData")
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    private static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// Widget에서 사용하는 구조체 (앱 측)
struct WidgetData: Codable {
    let todaySchedules: [WidgetScheduleItem]
    let monthIncome: Int
    let monthExpense: Int
    let monthName: String
}

struct WidgetScheduleItem: Codable, Identifiable {
    let id: String
    let title: String
    let category: String
    let time: String
    let colorHex: String
}

private extension ScheduleCategory {
    var colorHex: String {
        switch self {
        case .meeting: return "4A90D9"
        case .filming: return "F5A623"
        case .deadline: return "D0021B"
        case .personal: return "7ED321"
        case .other: return "9B9B9B"
        }
    }
}

