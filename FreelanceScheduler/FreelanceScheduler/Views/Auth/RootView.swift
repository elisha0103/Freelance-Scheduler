import SwiftUI

struct RootView: View {
    @Environment(AuthViewModel.self) var authViewModel

    var body: some View {
        Group {
            switch authViewModel.authState {
            case .loading:
                ProgressView("로딩 중...")
            case .loggedOut:
                LoginView()
            case .needsGroup:
                GroupCreateJoinView()
            case .loggedIn:
                MainTabView()
            }
        }
        .animation(.easeInOut, value: authViewModel.authState == .loggedIn)
    }
}
