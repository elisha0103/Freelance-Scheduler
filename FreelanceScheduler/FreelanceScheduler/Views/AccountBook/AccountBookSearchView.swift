import SwiftUI

struct AccountBookSearchView: View {
    @Environment(AccountBookViewModel.self) var accountBookVM
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var selectedFilter: IncomeExpense?
    @State private var useStartDate = false
    @State private var useEndDate = false
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate = Date()

    private var results: [AccountBook] {
        accountBookVM.accountBooks.filter { item in
            if !searchText.isEmpty {
                let matchTitle = item.title.localizedCaseInsensitiveContains(searchText)
                let matchMemo = item.memo?.localizedCaseInsensitiveContains(searchText) ?? false
                if !matchTitle && !matchMemo { return false }
            }
            if let filter = selectedFilter, item.type != filter { return false }
            if useStartDate, item.date < startDate.startOfDay { return false }
            if useEndDate, item.date > Calendar.current.date(byAdding: .day, value: 1, to: endDate.startOfDay)! { return false }
            return true
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("제목 또는 메모 검색", text: $searchText)
                }
                .padding(8).background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8)).padding(.horizontal)

                HStack(spacing: 12) {
                    FilterChip(title: "전체", isSelected: selectedFilter == nil) { selectedFilter = nil }
                    FilterChip(title: "수입", isSelected: selectedFilter == .income) { selectedFilter = .income }
                    FilterChip(title: "지출", isSelected: selectedFilter == .expense) { selectedFilter = .expense }
                }.padding(.horizontal).padding(.vertical, 8)

                VStack(spacing: 4) {
                    HStack {
                        Toggle("시작일", isOn: $useStartDate).font(.caption)
                        if useStartDate { DatePicker("", selection: $startDate, displayedComponents: .date).labelsHidden() }
                    }
                    HStack {
                        Toggle("종료일", isOn: $useEndDate).font(.caption)
                        if useEndDate { DatePicker("", selection: $endDate, displayedComponents: .date).labelsHidden() }
                    }
                }.padding(.horizontal)

                Divider().padding(.top, 8)

                if results.isEmpty {
                    ContentUnavailableView("검색 결과가 없습니다", systemImage: "magnifyingglass")
                } else {
                    List(results) { item in AccountBookRow(item: item) }.listStyle(.plain)
                }
            }
            .navigationTitle("가계부 검색").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("닫기") { dismiss() } } }
        }
    }
}

struct FilterChip: View {
    let title: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.caption).fontWeight(.medium)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.15))
                .foregroundStyle(isSelected ? .white : .primary).clipShape(Capsule())
        }.buttonStyle(.plain)
    }
}
