import SwiftUI

struct GroupManageView: View {
    @Environment(AuthViewModel.self) var authViewModel
    @Environment(GroupViewModel.self) var groupVM
    @Environment(\.dismiss) private var dismiss

    @State private var showRemoveAlert = false
    @State private var showLeaveAlert = false
    @State private var showDissolveAlert = false
    @State private var memberToRemove: FSUser?

    private var isLeader: Bool { authViewModel.currentUser?.isGroupLeader == true }

    var body: some View {
        List {
            Section("그룹 멤버") {
                ForEach(groupVM.members) { member in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(member.nickname)
                                    .font(.subheadline)
                                if member.id == groupVM.group?.leaderId {
                                    Text("그룹장")
                                        .font(.caption2)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundStyle(.blue)
                                        .clipShape(Capsule())
                                }
                            }
                            Text(member.createdAt.formattedDate)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()

                        if isLeader && member.id != authViewModel.currentUser?.id {
                            Button("추방", role: .destructive) {
                                memberToRemove = member
                                showRemoveAlert = true
                            }
                            .font(.caption)
                        }
                    }
                }
            }

            Section {
                if isLeader {
                    Button("그룹 폐쇄", role: .destructive) {
                        showDissolveAlert = true
                    }
                } else {
                    Button("그룹 탈퇴", role: .destructive) {
                        showLeaveAlert = true
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("그룹 관리")
        .navigationBarTitleDisplayMode(.inline)
        .alert("멤버 추방", isPresented: $showRemoveAlert) {
            Button("추방", role: .destructive) {
                guard let member = memberToRemove else { return }
                Task {
                    await groupVM.removeMember(userId: member.id)
                }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("\(memberToRemove?.nickname ?? "")님을 추방하시겠습니까?")
        }
        .alert("그룹 탈퇴", isPresented: $showLeaveAlert) {
            Button("탈퇴", role: .destructive) {
                guard let userId = authViewModel.currentUser?.id else { return }
                Task {
                    await groupVM.leaveGroup(userId: userId)
                    await authViewModel.refreshUser()
                }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("그룹을 탈퇴하시겠습니까?")
        }
        .alert("그룹 폐쇄", isPresented: $showDissolveAlert) {
            Button("폐쇄", role: .destructive) {
                guard let userId = authViewModel.currentUser?.id else { return }
                Task {
                    await groupVM.dissolveGroup(leaderId: userId)
                    await authViewModel.refreshUser()
                }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("그룹을 폐쇄하시겠습니까?\n모든 멤버가 자동 탈퇴됩니다.")
        }
    }
}
