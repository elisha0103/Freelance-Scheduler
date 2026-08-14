import Foundation
import Observation

@Observable
final class ScheduleViewModel {
    var schedules: [Schedule] = []
    var currentYear: Int
    var currentMonth: Int
    var isLoading = false
    var errorMessage: String?

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
            errorMessage = error.localizedDescription
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
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func deleteSchedule(_ schedule: Schedule) async {
        do {
            try await firestoreService.deleteSchedule(id: schedule.id)
            schedules.removeAll { $0.id == schedule.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func schedules(for date: Date) -> [Schedule] {
        schedules.filter { schedule in
            schedule.startDate.isSameDay(as: date)
                || (schedule.deadline?.isSameDay(as: date) == true)
        }
    }

    var datesWithSchedules: [Date] {
        var dateSet = Set<Date>()
        for schedule in schedules {
            dateSet.insert(schedule.startDate.startOfDay)
            if let deadline = schedule.deadline {
                dateSet.insert(deadline.startOfDay)
            }
        }
        return dateSet.sorted(by: >)
    }
}
