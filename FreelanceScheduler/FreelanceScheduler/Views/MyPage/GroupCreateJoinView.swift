import SwiftUI

struct GroupCreateJoinView: View {
    @Environment(AuthViewModel.self) var authViewModel
    @State private var groupVM = GroupViewModel()

    @State private var selectedTab = 0
    @State private var groupName = ""
    @State private var inviteCode = ""
    @State private var showError = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("그룹 설정")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 32)

                Text("프리랜서 스케줄러를 사용하려면\n그룹에 소속되어야 합니다.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Picker("", selection: $selectedTab) {
                    Text("그룹 생성").tag(0)
                    Text("초대 코드 입력").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)

                if selectedTab == 0 {
                    createGroupSection
                } else {
                    joinGroupSection
                }

                if let error = groupVM.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("로그아웃") {
                        Task { await authViewModel.logout() }
                    }
                    .font(.caption)
                }
            }
        }
    }

    private var createGroupSection: some View {
        VStack(spacing: 16) {
            TextField("그룹 이름", text: $groupName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 24)
                .onChange(of: groupName) {
                    if groupName.count > 20 { groupName = String(groupName.prefix(20)) }
                }

            Button {
                guard !groupName.isEmpty else { showError = true; return }
                guard let userId = authViewModel.currentUser?.id else { return }
                Task {
                    if let _ = await groupVM.createGroup(name: groupName, userId: userId) {
                        await authViewModel.refreshUser()
                    }
                }
            } label: {
                Text("그룹 생성")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(groupName.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(groupName.isEmpty)
            .padding(.horizontal, 24)
        }
    }

    private var joinGroupSection: some View {
        VStack(spacing: 16) {
            TextField("초대 코드 (6자리)", text: $inviteCode)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.characters)
                .padding(.horizontal, 24)
                .onChange(of: inviteCode) {
                    if inviteCode.count > 6 { inviteCode = String(inviteCode.prefix(6)) }
                    inviteCode = inviteCode.uppercased()
                }

            Button {
                guard inviteCode.count == 6 else { return }
                guard let userId = authViewModel.currentUser?.id else { return }
                Task {
                    if await groupVM.joinGroup(inviteCode: inviteCode, userId: userId) {
                        await authViewModel.refreshUser()
                    }
                }
            } label: {
                Text("그룹 참가")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(inviteCode.count == 6 ? Color.blue : Color.gray.opacity(0.3))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(inviteCode.count != 6)
            .padding(.horizontal, 24)
        }
    }
}
