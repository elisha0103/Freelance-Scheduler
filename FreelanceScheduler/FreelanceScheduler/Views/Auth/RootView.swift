import SwiftUI

struct RootView: View {
    @Environment(AuthViewModel.self) var authViewModel
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
            } else {
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
        }
        .animation(.easeInOut, value: authViewModel.authState == .loggedIn)
        .animation(.easeInOut, value: hasSeenOnboarding)
    }
}
