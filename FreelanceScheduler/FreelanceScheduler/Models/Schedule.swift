import Foundation
import SwiftUI

enum ScheduleCategory: String, Codable, CaseIterable, Identifiable {
    case meeting = "미팅/회의"
    case filming = "촬영/현장"
    case deadline = "마감/납품"
    case personal = "개인"
    case other = "기타"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .meeting: return Color(hex: "4A90D9")
        case .filming: return Color(hex: "F5A623")
        case .deadline: return Color(hex: "D0021B")
        case .personal: return Color(hex: "7ED321")
        case .other: return Color(hex: "9B9B9B")
        }
    }

    static let deadlineHighlightColor = Color(hex: "8B572A")
}

struct Schedule: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var category: ScheduleCategory
    var isGroupSchedule: Bool
    var startDate: Date
    var deadline: Date?
    var address: String?
    var latitude: Double?
    var longitude: Double?
    var amount: Int?
    var companions: [String]
    var description: String?
    var authorId: String
    var groupId: String
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        title: String,
        category: ScheduleCategory = .other,
        isGroupSchedule: Bool = false,
        startDate: Date = Date(),
        deadline: Date? = nil,
        address: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        amount: Int? = nil,
        companions: [String] = [],
        description: String? = nil,
        authorId: String,
        groupId: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.isGroupSchedule = isGroupSchedule
        self.startDate = startDate
        self.deadline = deadline
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.amount = amount
        self.companions = companions
        self.description = description
        self.authorId = authorId
        self.groupId = groupId
        self.createdAt = createdAt
    }
}
