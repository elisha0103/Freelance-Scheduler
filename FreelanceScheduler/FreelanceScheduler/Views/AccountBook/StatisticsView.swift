import SwiftUI
import Charts

struct StatisticsView: View {
    @Environment(AccountBookViewModel.self) var accountBookVM
    @Environment(\.dismiss) private var dismiss
    @State private var showMonthPicker = false
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    Text("월간").tag(0)
                    Text("연간").tag(1)
                    Text("세금").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                switch selectedTab {
                case 0: monthlyView
                case 1: annualView
                case 2: taxSummaryView
                default: EmptyView()
                }
            }
            .navigationTitle("통계").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("닫기") { dismiss() } } }
        }
    }

    // MARK: - 월간 통계
    private var monthlyView: some View {
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

            // 차트
            if !accountBookVM.statsAccountBooks.isEmpty {
                Chart {
                    BarMark(x: .value("항목", "수입"), y: .value("금액", accountBookVM.totalIncome))
                        .foregroundStyle(.green)
                    BarMark(x: .value("항목", "지출"), y: .value("금액", accountBookVM.totalExpense))
                        .foregroundStyle(.red)
                    BarMark(x: .value("항목", "세금"), y: .value("금액", accountBookVM.totalTax))
                        .foregroundStyle(.orange)
                }
                .frame(height: 180)
                .padding()

                // 지출 카테고리 파이차트
                let expenseByCategory = accountBookVM.expenseByCategoryForStats
                if !expenseByCategory.isEmpty {
                    Text("지출 카테고리").font(.subheadline).fontWeight(.semibold).padding(.top, 8)
                    Chart(expenseByCategory, id: \.category) { item in
                        SectorMark(
                            angle: .value("금액", item.amount),
                            innerRadius: .ratio(0.5),
                            angularInset: 1
                        )
                        .foregroundStyle(by: .value("카테고리", item.category.rawValue))
                    }
                    .frame(height: 180)
                    .padding(.horizontal)
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
    }

    // MARK: - 연간 통계
    private var annualView: some View {
        VStack(spacing: 0) {
            HStack {
                Button { accountBookVM.moveStatsYear(by: -1) } label: { Image(systemName: "chevron.left") }
                Text("\(String(accountBookVM.statsYear))년")
                    .font(.headline).foregroundStyle(.primary)
                Button { accountBookVM.moveStatsYear(by: 1) } label: { Image(systemName: "chevron.right") }
            }.padding()

            let monthlyData = accountBookVM.monthlyDataForYear
            if !monthlyData.isEmpty {
                Chart(monthlyData) { data in
                    BarMark(
                        x: .value("월", "\(data.month)월"),
                        y: .value("금액", data.income)
                    ).foregroundStyle(.green)
                    BarMark(
                        x: .value("월", "\(data.month)월"),
                        y: .value("금액", -data.expense)
                    ).foregroundStyle(.red)
                }
                .frame(height: 200)
                .padding()
            }

            List {
                let yearIncome = monthlyData.reduce(0) { $0 + $1.income }
                let yearExpense = monthlyData.reduce(0) { $0 + $1.expense }
                let yearTax = monthlyData.reduce(0) { $0 + $1.tax }
                StatRow(title: "연간 수입", amount: yearIncome, color: .green)
                StatRow(title: "연간 지출", amount: yearExpense, color: .red)
                StatRow(title: "연간 세금", amount: yearTax, color: .orange)
                HStack {
                    Text("연간 순이익").font(.headline)
                    Spacer()
                    let yearNet = yearIncome - yearExpense - yearTax
                    Text("\(yearNet.formatted())원").font(.headline)
                        .foregroundStyle(yearNet >= 0 ? .blue : .red)
                }.padding(.vertical, 4)
            }.listStyle(.insetGrouped)
        }
    }

    // MARK: - 세금 신고 요약
    private var taxSummaryView: some View {
        VStack(spacing: 0) {
            HStack {
                Button { accountBookVM.moveStatsYear(by: -1) } label: { Image(systemName: "chevron.left") }
                Text("\(String(accountBookVM.statsYear))년 세금 신고 요약")
                    .font(.headline).foregroundStyle(.primary)
                Button { accountBookVM.moveStatsYear(by: 1) } label: { Image(systemName: "chevron.right") }
            }.padding()

            let yearBooks = accountBookVM.accountBooks.filter { $0.date.year == accountBookVM.statsYear }
            let totalIncome = yearBooks.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let totalTax = yearBooks.filter { $0.hasTax }.reduce(0) { $0 + ($1.taxAmount ?? 0) }
            let totalExpense = yearBooks.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            let taxableIncome = totalIncome - totalExpense

            List {
                Section("수입") {
                    StatRow(title: "총 수입 (세전)", amount: totalIncome, color: .green)
                    StatRow(title: "원천징수 세금", amount: totalTax, color: .orange)
                    StatRow(title: "실수령 합계", amount: totalIncome - totalTax, color: .blue)
                }
                Section("경비") {
                    StatRow(title: "총 경비 (지출)", amount: totalExpense, color: .red)
                    let expenseByCategory = accountBookVM.expenseByCategoryForYear
                    ForEach(expenseByCategory, id: \.category) { item in
                        HStack {
                            Label(item.category.rawValue, systemImage: item.category.icon)
                                .font(.caption)
                            Spacer()
                            Text("\(item.amount.formatted())원")
                                .font(.caption).fontWeight(.semibold)
                        }
                    }
                }
                Section("과세 소득") {
                    HStack {
                        Text("과세 소득 (수입 - 경비)").font(.subheadline).fontWeight(.semibold)
                        Spacer()
                        Text("\(taxableIncome.formatted())원").font(.subheadline).fontWeight(.bold)
                            .foregroundStyle(taxableIncome >= 0 ? Color.primary : Color.red)
                    }
                    HStack {
                        Text("기납부 세액").font(.subheadline)
                        Spacer()
                        Text("\(totalTax.formatted())원").font(.subheadline).foregroundStyle(.orange)
                    }
                }
            }.listStyle(.insetGrouped)
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
