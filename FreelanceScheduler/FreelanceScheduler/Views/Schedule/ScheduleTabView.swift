import SwiftUI

struct ScheduleTabView: View {
    @Environment(AuthViewModel.self) var authViewModel
    @Environment(ScheduleViewModel.self) var scheduleVM
    @Environment(AccountBookViewModel.self) var accountBookVM
    @Environment(GroupViewModel.self) var groupVM

    @State private var showListView = false
    @State private var showAddPopover = false
    @State private var showScheduleForm = false
    @State private var showAccountBookForm = false

    var body: some View {
        NavigationStack {
            CalendarView()
                .refreshable { await reloadSchedules() }
                .navigationTitle("\(String(scheduleVM.currentYear))년 \(scheduleVM.currentMonth)월")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        HStack(spacing: 12) {
                            Button { showListView = true } label: {
                                Image(systemName: "list.bullet")
                            }
                            if groupVM.members.count > 1 {
                                Menu {
                                    Button("전체") { scheduleVM.filterAuthorId = nil }
                                    ForEach(groupVM.members) { member in
                                        Button(member.nickname) { scheduleVM.filterAuthorId = member.id }
                                    }
                                } label: {
                                    Image(systemName: scheduleVM.filterAuthorId == nil ? "person.2" : "person.fill")
                                }
                            }
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { showAddPopover = true } label: {
                            Image(systemName: "plus")
                        }
                        .popover(isPresented: $showAddPopover) {
                            AddPopover(
                                onScheduleTap: { showAddPopover = false; showScheduleForm = true },
                                onAccountBookTap: { showAddPopover = false; showAccountBookForm = true }
                            )
                        }
                    }
                }
                .fullScreenCover(isPresented: $showListView) {
                    ScheduleListView()
                }
                .fullScreenCover(isPresented: $showScheduleForm) {
                    ScheduleFormView(mode: .create) { await reloadSchedules() }
                }
                .fullScreenCover(isPresented: $showAccountBookForm) {
                    AccountBookFormView(mode: .create) { await reloadAccountBooks() }
                }
                .onChange(of: scheduleVM.currentMonth) {
                    Task { await reloadSchedules() }
                }
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
