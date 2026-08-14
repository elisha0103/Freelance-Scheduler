import SwiftUI

struct StatisticsView: View {
    @Environment(AccountBookViewModel.self) var accountBookVM
    @Environment(\.dismiss) private var dismiss
    @State private var showMonthPicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Button { accountBookVM.moveStatsMonth(by: -1) } label: { Image(systemName: "chevron.left") }
                    Button { showMonthPicker = true } label: {
                        Text("\(String(accountBookVM.statsYear))년 \(accountBookVM.statsMonth)월")
                            .font(.headline).foregroundStyle(.primary)
                    }
                    Button { accountBookVM.moveStatsMonth(by: 1) } label: { Image(systemName: "chevron.right") }
                }
                .padding()
                .alert("월 이동", isPresented: $showMonthPicker) {
                    MonthPickerAlert(year: accountBookVM.statsYear, month: accountBookVM.statsMonth) { y, m in
                        accountBookVM.moveStatsToMonth(year: y, month: m)
                    }
                }

                List {
                    StatRow(title: "총 수입", amount: accountBookVM.totalIncome, color: .green)
                    StatRow(title: "총 지출", amount: accountBookVM.totalExpense, color: .red)
                    StatRow(title: "부과 세금", amount: accountBookVM.totalTax, color: .orange)
                    HStack {
                        Text("\(accountBookVM.statsMonth)월 순이익").font(.headline)
                        Spacer()
                        Text("\(accountBookVM.netProfit.formatted())원").font(.headline)
                            .foregroundStyle(accountBookVM.netProfit >= 0 ? .blue : .red)
                    }.padding(.vertical, 4)
                }.listStyle(.insetGrouped)
            }
            .navigationTitle("통계").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("닫기") { dismiss() } } }
        }
    }
}

struct StatRow: View {
    let title: String; let amount: Int; let color: Color
    var body: some View {
        HStack {
            Text(title).font(.subheadline)
            Spacer()
            Text("\(amount.formatted())원").font(.subheadline).fontWeight(.semibold).foregroundStyle(color)
        }.padding(.vertical, 2)
    }
}
