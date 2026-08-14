import SwiftUI

struct ScheduleListView: View {
    @Environment(ScheduleViewModel.self) var scheduleVM
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if scheduleVM.datesWithSchedules.isEmpty {
                    ContentUnavailableView("등록된 일정이 없습니다", systemImage: "calendar.badge.exclamationmark")
                } else {
                    List {
                        ForEach(scheduleVM.datesWithSchedules, id: \.self) { date in
                            Section {
                                ForEach(scheduleVM.schedules(for: date)) { schedule in
                                    NavigationLink {
                                        ScheduleDetailView(schedule: schedule)
                                    } label: {
                                        ScheduleRow(
                                            schedule: schedule,
                                            date: date
                                        )
                                    }
                                }
                            } header: {
                                Text(date.formattedDate)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(Date(from: scheduleVM.currentYear, month: scheduleVM.currentMonth)?.formattedYearMonth ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
//            .navigationDestination(for: Schedule.self) { schedule in
//                ScheduleDetailView(schedule: schedule)
//            }
        }
    }
}

struct ScheduleRow: View {
    let schedule: Schedule
    let date: Date

    private var isDeadline: Bool {
        schedule.deadline?.isSameDay(as: date) == true && !schedule.startDate.isSameDay(as: date)
    }

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(isDeadline ? ScheduleCategory.deadlineHighlightColor : schedule.category.color)
                .frame(width: 4)
            VStack(alignment: .leading, spacing: 2) {
                Text(schedule.title).font(.subheadline).fontWeight(.medium)
                if isDeadline {
                    Text("마감일").font(.caption).foregroundStyle(.secondary)
                } else {
                    Text(schedule.startDate.formattedDateTime).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if schedule.isGroupSchedule {
                Image(systemName: "person.2.fill").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

private extension Date {
    init?(from year: Int, month: Int) {
        guard let date = Calendar.current.date(from: DateComponents(year: year, month: month, day: 1)) else { return nil }
        self = date
    }
}
