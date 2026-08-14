import Foundation
import SwiftUI

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case transportation = "교통비"
    case food = "식비"
    case equipment = "장비/소프트웨어"
    case office = "사무용품"
    case communication = "통신비"
    case education = "교육/세미나"
    case insurance = "보험"
    case other = "기타"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .transportation: return "car.fill"
        case .food: return "fork.knife"
        case .equipment: return "desktopcomputer"
        case .office: return "pencil.and.ruler"
        case .communication: return "phone.fill"
        case .education: return "graduationcap.fill"
        case .insurance: return "shield.fill"
        case .other: return "ellipsis.circle"
        }
    }
}

enum IncomeExpense: String, Codable, CaseIterable {
    case income = "수입"
    case expense = "지출"

    var color: Color {
        switch self {
        case .income: return .green
        case .expense: return .red
        }
    }
}

struct AccountBook: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var date: Date
    var type: IncomeExpense
    var amount: Int
    var hasTax: Bool
    var taxRate: Double?
    var taxAmount: Int?
    var netAmount: Int?
    var memo: String?
    var expenseCategory: ExpenseCategory?
    var authorId: String
    var groupId: String
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        title: String,
        date: Date = Date(),
        type: IncomeExpense,
        amount: Int,
        hasTax: Bool = false,
        taxRate: Double? = nil,
        taxAmount: Int? = nil,
        netAmount: Int? = nil,
        memo: String? = nil,
        expenseCategory: ExpenseCategory? = nil,
        authorId: String,
        groupId: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.type = type
        self.amount = amount
        self.hasTax = hasTax
        self.taxRate = taxRate
        self.taxAmount = taxAmount
        self.netAmount = netAmount
        self.memo = memo
        self.expenseCategory = expenseCategory
        self.authorId = authorId
        self.groupId = groupId
        self.createdAt = createdAt
    }

    var displayAmount: Int {
        if type == .income, hasTax, let net = netAmount {
            return net
        }
        return amount
    }
}
