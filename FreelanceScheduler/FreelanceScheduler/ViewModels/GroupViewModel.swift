import Foundation
import Observation

@Observable
final class GroupViewModel {
    var group: FSGroup?
    var members: [FSUser] = []
    var isLoading = false
    var errorMessage: String?
    var generatedInviteCode: String?

    private let firestoreService = FirestoreService.shared

    @MainActor
    func loadGroup(groupId: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            group = try await firestoreService.fetchGroup(id: groupId)
            if let memberIds = group?.memberIds {
                members = try await firestoreService.fetchGroupMembers(memberIds: memberIds)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func createGroup(name: String, userId: String) async -> FSGroup? {
        let newGroup = FSGroup(name: name, leaderId: userId, memberIds: [userId])
        do {
            try await firestoreService.createGroup(newGroup)
            try await firestoreService.updateUserGroup(userId: userId, groupId: newGroup.id, isLeader: true)
            group = newGroup
            return newGroup
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    @MainActor
    func joinGroup(inviteCode: String, userId: String) async -> Bool {
        do {
            guard var foundGroup = try await firestoreService.fetchGroupByInviteCode(inviteCode) else {
                errorMessage = "유효하지 않은 초대 코드입니다."
                return false
            }
            if let expiry = foundGroup.inviteCodeExpiry, expiry < Date() {
                errorMessage = "만료된 초대 코드입니다."
                return false
            }
            if foundGroup.memberIds.count >= FSGroup.maxMemberCount {
                errorMessage = "그룹 인원이 최대(\(FSGroup.maxMemberCount)명)에 도달했습니다."
                return false
            }
            if foundGroup.memberIds.contains(userId) {
                errorMessage = "이미 해당 그룹에 속해있습니다."
                return false
            }
            foundGroup.memberIds.append(userId)
            try await firestoreService.updateGroup(foundGroup)
            try await firestoreService.updateUserGroup(userId: userId, groupId: foundGroup.id, isLeader: false)
            group = foundGroup
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    @MainActor
    func generateInviteCode() async {
        guard var group else { return }
        let code = String((0..<6).map { _ in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()! })
        let expiry = Calendar.current.date(byAdding: .hour, value: 24, to: Date())!
        group.inviteCode = code
        group.inviteCodeExpiry = expiry
        do {
            try await firestoreService.updateGroup(group)
            self.group = group
            generatedInviteCode = code
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func removeMember(userId: String) async {
        guard var group else { return }
        group.memberIds.removeAll { $0 == userId }
        do {
            try await firestoreService.updateGroup(group)
            try await firestoreService.updateUserGroup(userId: userId, groupId: nil, isLeader: false)
            self.group = group
            members.removeAll { $0.id == userId }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func leaveGroup(userId: String) async {
        guard var group else { return }
        group.memberIds.removeAll { $0 == userId }
        do {
            try await firestoreService.updateGroup(group)
            try await firestoreService.updateUserGroup(userId: userId, groupId: nil, isLeader: false)
            self.group = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func dissolveGroup(leaderId: String) async {
        guard let group else { return }
        do {
            for memberId in group.memberIds {
                try await firestoreService.updateUserGroup(userId: memberId, groupId: nil, isLeader: false)
            }
            try await firestoreService.deleteGroup(id: group.id)
            self.group = nil
            members = []
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
