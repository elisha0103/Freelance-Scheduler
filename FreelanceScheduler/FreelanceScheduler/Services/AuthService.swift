import Foundation
import KakaoSDKUser
import KakaoSDKAuth
import KakaoSDKCommon

final class AuthService {
    static let shared = AuthService()

    private let userIdKey = "cachedKakaoUserId"

    private init() {}

    var cachedUserId: String? {
        UserDefaults.standard.string(forKey: userIdKey)
    }

    func loginWithKakao() async throws -> FSUser {
        let oauthToken: OAuthToken = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                if UserApi.isKakaoTalkLoginAvailable() {
                    UserApi.shared.loginWithKakaoTalk { token, error in
                        if let error { continuation.resume(throwing: error); return }
                        guard let token else {
                            continuation.resume(throwing: AuthError.noToken)
                            return
                        }
                        continuation.resume(returning: token)
                    }
                } else {
                    UserApi.shared.loginWithKakaoAccount { token, error in
                        if let error { continuation.resume(throwing: error); return }
                        guard let token else {
                            continuation.resume(throwing: AuthError.noToken)
                            return
                        }
                        continuation.resume(returning: token)
                    }
                }
            }
        }

        _ = oauthToken
        let kakaoUser = try await fetchKakaoUserInfo()
        let userId = String(kakaoUser.id ?? 0)
        let nickname = kakaoUser.kakaoAccount?.profile?.nickname ?? "사용자"
        let email = kakaoUser.kakaoAccount?.email ?? ""

        UserDefaults.standard.set(userId, forKey: userIdKey)

        // Firestore에서 기존 사용자 조회 또는 신규 생성
        if let existingUser = try await FirestoreService.shared.fetchUser(id: userId) {
            return existingUser
        }

        let newUser = FSUser(id: userId, nickname: nickname, email: email)
        try await FirestoreService.shared.saveUser(newUser)
        return newUser
    }

    func checkTokenAndAutoLogin() async throws -> FSUser? {
        guard cachedUserId != nil else { return nil }

        let hasToken: Bool = await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                if AuthApi.hasToken() {
                    UserApi.shared.accessTokenInfo { _, error in
                        continuation.resume(returning: error == nil)
                    }
                } else {
                    continuation.resume(returning: false)
                }
            }
        }

        guard hasToken, let userId = cachedUserId else {
            clearCache()
            return nil
        }

        return try await FirestoreService.shared.fetchUser(id: userId)
    }

    func logout() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.main.async {
                UserApi.shared.logout { _ in
                    continuation.resume()
                }
            }
        }
        clearCache()
    }

    private func fetchKakaoUserInfo() async throws -> KakaoSDKUser.User {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                UserApi.shared.me { user, error in
                    if let error { continuation.resume(throwing: error); return }
                    guard let user else {
                        continuation.resume(throwing: AuthError.noUserInfo)
                        return
                    }
                    continuation.resume(returning: user)
                }
            }
        }
    }

    private func clearCache() {
        UserDefaults.standard.removeObject(forKey: userIdKey)
    }
}

enum AuthError: LocalizedError {
    case noToken
    case noUserInfo

    var errorDescription: String? {
        switch self {
        case .noToken: return "로그인 토큰을 받지 못했습니다."
        case .noUserInfo: return "사용자 정보를 가져올 수 없습니다."
        }
    }
}
