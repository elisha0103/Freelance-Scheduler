import Foundation
import FirebaseFirestore

final class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - User

    func saveUser(_ user: FSUser) async throws {
        try db.collection("users").document(user.id).setData(from: user, merge: true)
    }

    func fetchUser(id: String) async throws -> FSUser? {
        let doc = try await db.collection("users").document(id).getDocument()
        return try? doc.data(as: FSUser.self)
    }

    func updateUserNickname(userId: String, nickname: String) async throws {
        try await db.collection("users").document(userId).updateData(["nickname": nickname])
    }

    func updateUserGroup(userId: String, groupId: String?, isLeader: Bool) async throws {
        try await db.collection("users").document(userId).updateData([
            "groupId": groupId as Any,
            "isGroupLeader": isLeader
        ])
    }

    // MARK: - Group

    func createGroup(_ group: FSGroup) async throws {
        try db.collection("groups").document(group.id).setData(from: group)
    }

    func fetchGroup(id: String) async throws -> FSGroup? {
        let doc = try await db.collection("groups").document(id).getDocument()
        return try? doc.data(as: FSGroup.self)
    }

    func fetchGroupByInviteCode(_ code: String) async throws -> FSGroup? {
        let snapshot = try await db.collection("groups")
            .whereField("inviteCode", isEqualTo: code)
            .getDocuments()
        guard let doc = snapshot.documents.first else { return nil }
        return try? doc.data(as: FSGroup.self)
    }

    func updateGroup(_ group: FSGroup) async throws {
        try db.collection("groups").document(group.id).setData(from: group, merge: true)
    }

    func deleteGroup(id: String) async throws {
        try await db.collection("groups").document(id).delete()
    }

    func fetchGroupMembers(memberIds: [String]) async throws -> [FSUser] {
        guard !memberIds.isEmpty else { return [] }
        var users: [FSUser] = []
        // Firestore 'in' 쿼리는 최대 30개
        for chunk in memberIds.chunked(into: 30) {
            let snapshot = try await db.collection("users")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            let chunkUsers = snapshot.documents.compactMap { try? $0.data(as: FSUser.self) }
            users.append(contentsOf: chunkUsers)
        }
        return users
    }

    // MARK: - Schedule

    func saveSchedule(_ schedule: Schedule) async throws {
        try db.collection("schedules").document(schedule.id).setData(from: schedule)
    }

    func fetchSchedules(groupId: String, authorId: String, year: Int, month: Int) async throws -> [Schedule] {
        let calendar = Calendar.current
        let startComponents = DateComponents(year: year, month: month, day: 1)
        guard let startDate = calendar.date(from: startComponents),
              let endDate = calendar.date(byAdding: .month, value: 1, to: startDate) else {
            return []
        }

        // groupId 기준으로 모든 일정 조회 (복합 인덱스 불필요)
        let groupSnapshot = try await db.collection("schedules")
            .whereField("groupId", isEqualTo: groupId)
            .getDocuments()

        // 개인 일정 (isGroupSchedule=false인 것 중 authorId 매칭)
        let personalSnapshot = try await db.collection("schedules")
            .whereField("authorId", isEqualTo: authorId)
            .getDocuments()

        var allSchedules: [Schedule] = []
        allSchedules.append(contentsOf: groupSnapshot.documents.compactMap { try? $0.data(as: Schedule.self) })

        // 개인 일정 중 그룹 일정이 아닌 것만 추가 (중복 방지)
        let personalSchedules = personalSnapshot.documents.compactMap { try? $0.data(as: Schedule.self) }
        for schedule in personalSchedules where !schedule.isGroupSchedule && !allSchedules.contains(where: { $0.id == schedule.id }) {
            allSchedules.append(schedule)
        }

        // 클라이언트에서 월 필터링
        return allSchedules.filter { schedule in
            let startInMonth = schedule.startDate >= startDate && schedule.startDate < endDate
            let deadlineInMonth = schedule.deadline.map { $0 >= startDate && $0 < endDate } ?? false
            return startInMonth || deadlineInMonth
        }
    }

    func deleteSchedule(id: String) async throws {
        try await db.collection("schedules").document(id).delete()
    }

    // MARK: - AccountBook

    func saveAccountBook(_ item: AccountBook) async throws {
        try db.collection("accountBooks").document(item.id).setData(from: item)
    }

    func fetchAccountBooks(groupId: String) async throws -> [AccountBook] {
        let snapshot = try await db.collection("accountBooks")
            .whereField("groupId", isEqualTo: groupId)
            .order(by: "date", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: AccountBook.self) }
    }

    func fetchAccountBooks(groupId: String, year: Int, month: Int) async throws -> [AccountBook] {
        let calendar = Calendar.current
        let startComponents = DateComponents(year: year, month: month, day: 1)
        guard let startDate = calendar.date(from: startComponents),
              let endDate = calendar.date(byAdding: .month, value: 1, to: startDate) else {
            return []
        }

        let snapshot = try await db.collection("accountBooks")
            .whereField("groupId", isEqualTo: groupId)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startDate))
            .whereField("date", isLessThan: Timestamp(date: endDate))
            .order(by: "date", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: AccountBook.self) }
    }

    func deleteAccountBook(id: String) async throws {
        try await db.collection("accountBooks").document(id).delete()
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
