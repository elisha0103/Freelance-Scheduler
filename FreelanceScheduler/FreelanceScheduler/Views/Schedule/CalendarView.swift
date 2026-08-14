import SwiftUI

struct CalendarView: View {
    @Environment(ScheduleViewModel.self) var scheduleVM
    @Environment(AccountBookViewModel.self) var accountBookVM
    @State private var showMonthPicker = false

    private let weekdays = ["일", "월", "화", "수", "목", "금", "토"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { scheduleVM.moveMonth(by: -1) } label: {
                    Image(systemName: "chevron.left")
                }
                Button { showMonthPicker = true } label: {
                    Text("\(String(scheduleVM.currentYear))년 \(scheduleVM.currentMonth)월")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                Button { scheduleVM.moveMonth(by: 1) } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.vertical, 8)
            .alert("월 이동", isPresented: $showMonthPicker) {
                MonthPickerAlert(
                    year: scheduleVM.currentYear,
                    month: scheduleVM.currentMonth
                ) { year, month in
                    scheduleVM.moveToMonth(year: year, month: month)
                }
            }

            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(day == "일" ? .red : day == "토" ? .blue : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
            }

            Divider()

            LazyVGrid(columns: columns, spacing: 0) {
                let firstWeekday = Date.firstWeekdayOfMonth(year: scheduleVM.currentYear, month: scheduleVM.currentMonth)
                let daysInMonth = Date.daysInMonth(year: scheduleVM.currentYear, month: scheduleVM.currentMonth)

                let totalCells = (firstWeekday - 1) + daysInMonth

                ForEach(0..<totalCells, id: \.self) { index in
                    if index < firstWeekday - 1 {
                        Color.clear
                            .frame(height: 80)
                    } else {
                        let day = index - (firstWeekday - 1) + 1
                        let date = makeDate(day: day)

                        NavigationLink(value: date) {
                            DayCell(
                                day: day,
                                date: date,
                                schedules: scheduleVM.schedules(for: date),
                                accountBooks: accountBookVM.accountBooks(for: date)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationDestination(for: Date.self) { date in
                DayDetailView(date: date)
            }

            Spacer()
        }
        .padding(.horizontal, 4)
    }

    private func makeDate(day: Int) -> Date {
        Calendar.current.date(from: DateComponents(
            year: scheduleVM.currentYear, month: scheduleVM.currentMonth, day: day
        )) ?? Date()
    }
}

struct DayCell: View {
    let day: Int
    let date: Date
    let schedules: [Schedule]
    let accountBooks: [AccountBook]

    private var isToday: Bool { date.isSameDay(as: Date()) }

    private var allItems: [(title: String, color: Color, isDeadline: Bool)] {
        var items: [(String, Color, Bool)] = []
        for s in schedules {
            if s.startDate.isSameDay(as: date) {
                items.append((s.title, s.category.color, false))
            }
            if s.deadline?.isSameDay(as: date) == true && !s.startDate.isSameDay(as: date) {
                items.append(("\(s.title) (마감)", ScheduleCategory.deadlineHighlightColor, true))
            }
        }
        for ab in accountBooks {
            items.append((ab.title, ab.type.color, false))
        }
        return items
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("\(day)")
                .font(.caption2)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(isToday ? .white : .primary)
                .frame(width: 20, height: 20)
                .background(isToday ? Color.blue : Color.clear)
                .clipShape(Circle())

            let displayItems = allItems
            let maxDisplay = 3

            if displayItems.count <= maxDisplay {
                ForEach(0..<displayItems.count, id: \.self) { i in
                    itemLabel(displayItems[i].title, color: displayItems[i].color)
                }
            } else {
                ForEach(0..<2, id: \.self) { i in
                    itemLabel(displayItems[i].title, color: displayItems[i].color)
                }
                itemLabel("\(displayItems[2].title) +\(displayItems.count - 3)", color: displayItems[2].color)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 80)
        .padding(2)
    }

    private func itemLabel(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9))
            .lineLimit(1)
            .padding(.horizontal, 3)
            .padding(.vertical, 1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 2))
    }
}
