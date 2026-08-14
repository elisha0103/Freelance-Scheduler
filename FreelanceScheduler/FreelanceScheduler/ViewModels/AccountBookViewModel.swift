import Foundation
import Observation

enum ErrorMessageHelper {
    static func userFriendlyMessage(_ error: Error) -> String {
        let desc = error.localizedDescription
        if desc.contains("index") || desc.contains("requires an index") {
            return "데이터 조회 중 문제가 발생했습니다. 잠시 후 다시 시도해주세요."
        } else if desc.contains("permission") || desc.contains("Permission") {
            return "접근 권한이 없습니다. 다시 로그인해주세요."
        } else if desc.contains("network") || desc.contains("Network") || desc.contains("offline") {
            return "네트워크 연결을 확인해주세요."
        }
        return "오류가 발생했습니다. 잠시 후 다시 시도해주세요."
    }
}

@Observable
final class AccountBookViewModel {
    var accountBooks: [AccountBook] = []
    var isLoading = false
    var errorMessage: String?
    var statsYear: Int
    var statsMonth: Int
    var searchText = ""
    var searchFilter: IncomeExpense?
    var searchStartDate: Date?
    var searchEndDate: Date?

    private let firestoreService = FirestoreService.shared

    init() {
        let now = Date()
        statsYear = now.year
        statsMonth = now.month
    }

    @MainActor
    func loadAccountBooks(groupId: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            accountBooks = try await firestoreService.fetchAccountBooks(groupId: groupId)
        } catch {
            errorMessage = ErrorMessageHelper.userFriendlyMessage(error)
        }
    }

    @MainActor
    func saveAccountBook(_ item: AccountBook) async {
        do {
            try await firestoreService.saveAccountBook(item)
        } catch {
            errorMessage = ErrorMessageHelper.userFriendlyMessage(error)
        }
    }

    @MainActor
    func deleteAccountBook(_ item: AccountBook) async {
        do {
            try await firestoreService.deleteAccountBook(id: item.id)
            accountBooks.removeAll { $0.id == item.id }
        } catch {
            errorMessage = ErrorMessageHelper.userFriendlyMessage(error)
        }
    }

    var filteredAccountBooks: [AccountBook] {
        accountBooks.filter { item in
            if !searchText.isEmpty {
                let matchTitle = item.title.localizedCaseInsensitiveContains(searchText)
                let matchMemo = item.memo?.localizedCaseInsensitiveContains(searchText) ?? false
                if !matchTitle && !matchMemo { return false }
            }
            if let filter = searchFilter, item.type != filter { return false }
            if let start = searchStartDate, item.date < start.startOfDay { return false }
            if let end = searchEndDate, item.date > Calendar.current.date(byAdding: .day, value: 1, to: end.startOfDay)! { return false }
            return true
        }
    }

    func moveStatsMonth(by offset: Int) {
        var month = statsMonth + offset
        var year = statsYear
        if month > 12 { month = 1; year += 1 }
        if month < 1 { month = 12; year -= 1 }
        statsMonth = month
        statsYear = year
    }

    func moveStatsToMonth(year: Int, month: Int) {
        statsYear = year
        statsMonth = month
    }

    var statsAccountBooks: [AccountBook] {
        accountBooks.filter { $0.date.year == statsYear && $0.date.month == statsMonth }
    }

    var totalIncome: Int {
        statsAccountBooks.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    var totalExpense: Int {
        statsAccountBooks.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    var totalTax: Int {
        statsAccountBooks.filter { $0.hasTax }.reduce(0) { $0 + ($1.taxAmount ?? 0) }
    }

    var netProfit: Int {
        totalIncome - totalExpense - totalTax
    }

    func accountBooks(for date: Date) -> [AccountBook] {
        accountBooks.filter { $0.date.isSameDay(as: date) }
    }

    // MARK: - 연간 통계
    func moveStatsYear(by offset: Int) {
        statsYear += offset
    }

    struct MonthlyData: Identifiable {
        let month: Int
        let income: Int
        let expense: Int
        let tax: Int
        var id: Int { month }
    }

    var monthlyDataForYear: [MonthlyData] {
        (1...12).map { month in
            let books = accountBooks.filter { $0.date.year == statsYear && $0.date.month == month }
            return MonthlyData(
                month: month,
                income: books.filter { $0.type == .income }.reduce(0) { $0 + $1.amount },
                expense: books.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount },
                tax: books.filter { $0.hasTax }.reduce(0) { $0 + ($1.taxAmount ?? 0) }
            )
        }.filter { $0.income > 0 || $0.expense > 0 || $0.tax > 0 }
    }

    // MARK: - 카테고리별 지출 집계
    struct CategoryAmount {
        let category: ExpenseCategory
        let amount: Int
    }

    var expenseByCategoryForStats: [CategoryAmount] {
        let expenses = statsAccountBooks.filter { $0.type == .expense }
        return aggregateByCategory(expenses)
    }

    var expenseByCategoryForYear: [CategoryAmount] {
        let expenses = accountBooks.filter { $0.type == .expense && $0.date.year == statsYear }
        return aggregateByCategory(expenses)
    }

    private func aggregateByCategory(_ items: [AccountBook]) -> [CategoryAmount] {
        var dict: [ExpenseCategory: Int] = [:]
        for item in items {
            let cat = item.expenseCategory ?? .other
            dict[cat, default: 0] += item.amount
        }
        return dict.map { CategoryAmount(category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }
}
