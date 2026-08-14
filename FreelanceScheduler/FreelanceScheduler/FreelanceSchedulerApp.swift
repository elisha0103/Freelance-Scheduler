import SwiftUI
import KakaoSDKAuth

@main
struct FreelanceSchedulerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authViewModel)
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .onOpenURL { url in
                    if AuthApi.isKakaoTalkLoginUrl(url) {
                        _ = AuthController.handleOpenUrl(url: url)
                    }
                }
        }
    }
}
