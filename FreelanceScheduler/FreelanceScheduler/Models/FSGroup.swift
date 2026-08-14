import Foundation

struct FSGroup: Codable, Identifiable {
    var id: String
    var name: String
    var leaderId: String
    var memberIds: [String]
    var inviteCode: String?
    var inviteCodeExpiry: Date?
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        leaderId: String,
        memberIds: [String] = [],
        inviteCode: String? = nil,
        inviteCodeExpiry: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.leaderId = leaderId
        self.memberIds = memberIds
        self.inviteCode = inviteCode
        self.inviteCodeExpiry = inviteCodeExpiry
        self.createdAt = createdAt
    }

    static let maxMemberCount = 10
}
