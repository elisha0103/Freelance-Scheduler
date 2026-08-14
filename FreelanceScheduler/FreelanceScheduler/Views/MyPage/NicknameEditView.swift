import SwiftUI

struct NicknameEditView: View {
    @Environment(AuthViewModel.self) var authViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var nickname = ""
    @State private var showError = false

    private var isValid: Bool { nickname.count >= 2 && nickname.count <= 10 }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("닉네임", text: $nickname)
                        .onChange(of: nickname) {
                            if nickname.count > 10 { nickname = String(nickname.prefix(10)) }
                        }
                } footer: {
                    Text("2~10자 사이로 입력해주세요. (\(nickname.count)/10)")
                        .foregroundStyle(isValid ? Color.secondary : Color.red)
                }
            }
            .navigationTitle("닉네임 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        guard isValid else { showError = true; return }
                        Task {
                            await authViewModel.updateNickname(nickname)
                            dismiss()
                        }
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                nickname = authViewModel.currentUser?.nickname ?? ""
            }
        }
    }
}
