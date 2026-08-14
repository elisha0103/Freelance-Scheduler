import Foundation

struct FSUser: Codable, Identifiable, Hashable {
    var id: String // 카카오 사용자 ID
    var nickname: String
    var email: String
    var groupId: String?
    var isGroupLeader: Bool
    var createdAt: Date

    init(
        id: String,
        nickname: String,
        email: String = "",
        groupId: String? = nil,
        isGroupLeader: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.nickname = nickname
        self.email = email
        self.groupId = groupId
        self.isGroupLeader = isGroupLeader
        self.createdAt = createdAt
    }
}
