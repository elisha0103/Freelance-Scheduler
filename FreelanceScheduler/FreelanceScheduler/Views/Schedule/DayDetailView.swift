import SwiftUI

struct DayDetailView: View {
    let date: Date

    @Environment(AuthViewModel.self) var authViewModel
    @Environment(ScheduleViewModel.self) var scheduleVM
    @Environment(AccountBookViewModel.self) var accountBookVM

    @State private var showAddPopover = false
    @State private var showScheduleForm = false
    @State private var showAccountBookForm = false

    private var daySchedules: [Schedule] { scheduleVM.schedules(for: date) }
    private var dayAccountBooks: [AccountBook] { accountBookVM.accountBooks(for: date) }

    var body: some View {
        List {
            Section("일정") {
                if daySchedules.isEmpty {
                    Text("등록된 일정이 없습니다").font(.subheadline).foregroundStyle(.secondary)
                } else {
                    ForEach(daySchedules) { schedule in
                        NavigationLink(value: schedule) {
                            ScheduleRow(schedule: schedule, date: date)
                        }
                    }
                }
            }
            Section("가계부") {
                if dayAccountBooks.isEmpty {
                    Text("등록된 가계부가 없습니다").font(.subheadline).foregroundStyle(.secondary)
                } else {
                    ForEach(dayAccountBooks) { item in
                        HStack {
                            Text(item.title).font(.subheadline)
                            Spacer()
                            Text("\(item.type == .income ? "+" : "-")\(item.amount.formatted())원")
                                .font(.subheadline).fontWeight(.medium).foregroundStyle(item.type.color)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(date.formattedDate)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAddPopover = true } label: { Image(systemName: "plus") }
                .popover(isPresented: $showAddPopover) {
                    AddPopover(
                        onScheduleTap: {
                            showAddPopover = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showScheduleForm = true }
                        },
                        onAccountBookTap: {
                            showAddPopover = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showAccountBookForm = true }
                        }
                    )
                }
            }
        }
        .navigationDestination(for: Schedule.self) { schedule in
            ScheduleDetailView(schedule: schedule)
        }
        .fullScreenCover(isPresented: $showScheduleForm) {
            ScheduleFormView(mode: .create, initialDate: date) { await reloadSchedules() }
        }
        .fullScreenCover(isPresented: $showAccountBookForm) {
            AccountBookFormView(mode: .create, initialDate: date) { await reloadAccountBooks() }
        }
    }

    private func reloadSchedules() async {
        guard let user = authViewModel.currentUser, let groupId = user.groupId else { return }
        await scheduleVM.loadSchedules(groupId: groupId, authorId: user.id)
    }

    private func reloadAccountBooks() async {
        guard let groupId = authViewModel.currentUser?.groupId else { return }
        await accountBookVM.loadAccountBooks(groupId: groupId)
    }
}
