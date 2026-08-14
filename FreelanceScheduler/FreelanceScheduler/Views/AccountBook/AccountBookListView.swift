import SwiftUI

struct AccountBookListView: View {
    @Environment(AccountBookViewModel.self) var accountBookVM
    @Environment(AuthViewModel.self) var authViewModel
    @State private var selectedItem: AccountBook?

    var body: some View {
        List {
            ForEach(accountBookVM.accountBooks) { item in
                Button { selectedItem = item } label: { AccountBookRow(item: item) }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task { await accountBookVM.deleteAccountBook(item); await reloadAccountBooks() }
                        } label: { Label("삭제", systemImage: "trash") }
                    }
            }
        }
        .listStyle(.insetGrouped)
        .fullScreenCover(item: $selectedItem) { item in
            AccountBookFormView(mode: .edit(item)) { await reloadAccountBooks() }
        }
    }

    private func reloadAccountBooks() async {
        guard let groupId = authViewModel.currentUser?.groupId else { return }
        await accountBookVM.loadAccountBooks(groupId: groupId)
    }
}

struct AccountBookRow: View {
    let item: AccountBook

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title).font(.subheadline).fontWeight(.medium)
                Text(item.date.formattedDate).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(item.type == .income ? "+" : "-")\(item.amount.formatted())원")
                    .font(.subheadline).fontWeight(.semibold).foregroundStyle(item.type.color)
                if item.hasTax {
                    Text("세금 포함").font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
