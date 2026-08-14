import Foundation
import Observation

enum AuthState {
    case loading
    case loggedOut
    case needsGroup
    case loggedIn
}

@Observable
final class AuthViewModel {
    var authState: AuthState = .loading
    var currentUser: FSUser?
    var errorMessage: String?

    init() {
        Task { await checkAutoLogin() }
    }

    @MainActor
    func checkAutoLogin() async {
        do {
            if let user = try await AuthService.shared.checkTokenAndAutoLogin() {
                currentUser = user
                authState = user.groupId != nil ? .loggedIn : .needsGroup
            } else {
                authState = .loggedOut
            }
        } catch {
            authState = .loggedOut
        }
    }

    @MainActor
    func loginWithKakao() async {
        do {
            let user = try await AuthService.shared.loginWithKakao()
            currentUser = user
            authState = user.groupId != nil ? .loggedIn : .needsGroup
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func logout() async {
        await AuthService.shared.logout()
        currentUser = nil
        authState = .loggedOut
    }

    @MainActor
    func refreshUser() async {
        guard let userId = currentUser?.id else { return }
        do {
            if let user = try await FirestoreService.shared.fetchUser(id: userId) {
                currentUser = user
                authState = user.groupId != nil ? .loggedIn : .needsGroup
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func updateNickname(_ nickname: String) async {
        guard let userId = currentUser?.id else { return }
        do {
            try await FirestoreService.shared.updateUserNickname(userId: userId, nickname: nickname)
            currentUser?.nickname = nickname
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
