import SwiftUI

struct AccountBookTabView: View {
    @Environment(AuthViewModel.self) var authViewModel
    @Environment(AccountBookViewModel.self) var accountBookVM

    @State private var showSearch = false
    @State private var showStatistics = false
    @State private var showForm = false

    var body: some View {
        NavigationStack {
            Group {
                if accountBookVM.accountBooks.isEmpty {
                    ContentUnavailableView("등록된 가계부가 없습니다", systemImage: "wonsign.circle")
                } else {
                    AccountBookListView()
                }
            }
            .task { await reloadAccountBooks() }
            .refreshable { await reloadAccountBooks() }
            .navigationTitle("가계부").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSearch = true } label: { Image(systemName: "magnifyingglass") }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { showStatistics = true } label: { Image(systemName: "chart.bar") }
                    Button { showForm = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showSearch) { AccountBookSearchView() }
            .sheet(isPresented: $showStatistics) { StatisticsView() }
            .fullScreenCover(isPresented: $showForm) {
                AccountBookFormView(mode: .create) { await reloadAccountBooks() }
            }
        }
    }

    private func reloadAccountBooks() async {
        guard let groupId = authViewModel.currentUser?.groupId else { return }
        await accountBookVM.loadAccountBooks(groupId: groupId)
    }
}
