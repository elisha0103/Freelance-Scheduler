import Foundation
import Observation

@Observable
final class ScheduleViewModel {
    var schedules: [Schedule] = []
    var currentYear: Int
    var currentMonth: Int
    var isLoading = false
    var errorMessage: String?
    var filterAuthorId: String?

    private let firestoreService = FirestoreService.shared

    init() {
        let now = Date()
        currentYear = now.year
        currentMonth = now.month
    }

    @MainActor
    func loadSchedules(groupId: String, authorId: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            schedules = try await firestoreService.fetchSchedules(
                groupId: groupId, authorId: authorId,
                year: currentYear, month: currentMonth
            )
        } catch {
            errorMessage = ErrorMessageHelper.userFriendlyMessage(error)
        }
    }

    func moveMonth(by offset: Int) {
        var month = currentMonth + offset
        var year = currentYear
        if month > 12 { month = 1; year += 1 }
        if month < 1 { month = 12; year -= 1 }
        currentMonth = month
        currentYear = year
    }

    func moveToMonth(year: Int, month: Int) {
        currentYear = year
        currentMonth = month
    }

    @MainActor
    func saveSchedule(_ schedule: Schedule) async {
        do {
            try await firestoreService.saveSchedule(schedule)
            NotificationService.scheduleReminder(for: schedule)
        } catch {
            errorMessage = ErrorMessageHelper.userFriendlyMessage(error)
        }
    }

    @MainActor
    func deleteSchedule(_ schedule: Schedule) async {
        do {
            try await firestoreService.deleteSchedule(id: schedule.id)
            NotificationService.cancelReminder(for: schedule.id)
            schedules.removeAll { $0.id == schedule.id }
        } catch {
            errorMessage = ErrorMessageHelper.userFriendlyMessage(error)
        }
    }

    var filteredSchedules: [Schedule] {
        guard let filterId = filterAuthorId else { return schedules }
        return schedules.filter { $0.authorId == filterId }
    }

    func schedules(for date: Date) -> [Schedule] {
        filteredSchedules.filter { schedule in
            schedule.startDate.isSameDay(as: date)
                || (schedule.deadline?.isSameDay(as: date) == true)
        }
    }

    var unpaidSchedules: [Schedule] {
        filteredSchedules.filter {
            ($0.category == .deadline || ($0.deadline != nil && $0.amount != nil)) && !$0.isPaid
        }.sorted { $0.startDate < $1.startDate }
    }

    var datesWithSchedules: [Date] {
        var dateSet = Set<Date>()
        for schedule in filteredSchedules {
            dateSet.insert(schedule.startDate.startOfDay)
            if let deadline = schedule.deadline {
                dateSet.insert(deadline.startOfDay)
            }
        }
        return dateSet.sorted(by: >)
    }
}
