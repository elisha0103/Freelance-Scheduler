import Foundation
import SwiftUI

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
