import SwiftUI

struct MainTabView: View {
    @Environment(AuthViewModel.self) var authViewModel
    @State private var scheduleVM = ScheduleViewModel()
    @State private var accountBookVM = AccountBookViewModel()
    @State private var groupVM = GroupViewModel()

    var body: some View {
        TabView {
            Tab("일정", systemImage: "calendar") {
                ScheduleTabView()
            }

            Tab("가계부", systemImage: "wonsign.circle") {
                AccountBookTabView()
            }

            Tab("마이페이지", systemImage: "person.circle") {
                MyPageTabView()
            }
        }
        .environment(scheduleVM)
        .environment(accountBookVM)
        .environment(groupVM)
        .errorBanner(message: scheduleVM.errorMessage ?? accountBookVM.errorMessage ?? groupVM.errorMessage) {
            scheduleVM.errorMessage = nil
            accountBookVM.errorMessage = nil
            groupVM.errorMessage = nil
        }
        .task {
            if let groupId = authViewModel.currentUser?.groupId {
                await groupVM.loadGroup(groupId: groupId)
            }
            await loadData()
        }
    }

    private func loadData() async {
        guard let user = authViewModel.currentUser, let groupId = user.groupId else { return }
        await scheduleVM.loadSchedules(groupId: groupId, authorId: user.id)
        await accountBookVM.loadAccountBooks(groupId: groupId)
        WidgetService.updateWidget(schedules: scheduleVM.schedules, accountBooks: accountBookVM.accountBooks)
    }
}
