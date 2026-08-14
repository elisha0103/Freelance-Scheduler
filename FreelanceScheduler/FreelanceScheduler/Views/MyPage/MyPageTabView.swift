import SwiftUI

struct MyPageTabView: View {
    @Environment(AuthViewModel.self) var authViewModel
    @Environment(GroupViewModel.self) var groupVM

    @State private var showNicknameEdit = false
    @State private var showGroupManage = false
    @State private var showLogoutAlert = false
    @State private var showInviteCode = false

    var body: some View {
        NavigationStack {
            List {
                // 프로필 섹션
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authViewModel.currentUser?.nickname ?? "사용자")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text(authViewModel.currentUser?.email ?? "")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("편집") { showNicknameEdit = true }
                            .font(.subheadline)
                    }
                }

                // 그룹 섹션
                Section("그룹") {
                    HStack {
                        Text(groupVM.group?.name ?? "-")
                            .font(.subheadline)
                        Spacer()
                        if authViewModel.currentUser?.isGroupLeader == true {
                            Text("그룹장")
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.blue.opacity(0.1))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }
                    }

                    if authViewModel.currentUser?.isGroupLeader == true {
                        Button {
                            Task { await groupVM.generateInviteCode() }
                            showInviteCode = true
                        } label: {
                            Label("그룹 초대", systemImage: "person.badge.plus")
                        }
                    }

                    Button {
                        showGroupManage = true
                    } label: {
                        Label("그룹 관리", systemImage: "gearshape")
                    }
                }

                // 기타 섹션
                Section {
                    Button(role: .destructive) {
                        showLogoutAlert = true
                    } label: {
                        Label("로그아웃", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("마이페이지")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showNicknameEdit) {
                NicknameEditView()
            }
            .navigationDestination(isPresented: $showGroupManage) {
                GroupManageView()
            }
            .alert("초대 코드", isPresented: $showInviteCode) {
                if let code = groupVM.generatedInviteCode {
                    Button("복사") {
                        UIPasteboard.general.string = code
                    }
                }
                Button("닫기", role: .cancel) {}
            } message: {
                if let code = groupVM.generatedInviteCode {
                    Text("초대 코드: \(code)\n(24시간 유효)")
                }
            }
            .alert("로그아웃", isPresented: $showLogoutAlert) {
                Button("로그아웃", role: .destructive) {
                    Task { await authViewModel.logout() }
                }
                Button("취소", role: .cancel) {}
            } message: {
                Text("로그아웃하시겠습니까?")
            }
        }
    }
}
