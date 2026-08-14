import SwiftUI

struct LoginView: View {
    @Environment(AuthViewModel.self) var authViewModel

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(.blue)

                Text("프리랜서 스케줄러")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("일정과 가계부를 한 곳에서 관리하세요")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                Task { await authViewModel.loginWithKakao() }
            } label: {
                HStack {
                    Image(systemName: "message.fill")
                    Text("카카오 로그인")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(hex: "FEE500"))
                .foregroundStyle(.black.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)

            if let error = authViewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer()
                .frame(height: 40)
        }
    }
}
