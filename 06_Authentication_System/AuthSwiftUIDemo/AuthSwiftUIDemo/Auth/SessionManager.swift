//
//  SessionManager.swift
//  AuthSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation
import Observation

@Observable
final class SessionManager {
    private(set) var state: SessionState = .checking
    private(set) var user: User?
    private(set) var expiryMessage: String?

    let apiClient: APIClient
    private let tokenStore: TokenStore
    private let authAPI: AuthAPI
    private let userKey = "cachedUser"

    init() {
        let tokenStore = TokenStore()
        let authAPI = AuthAPI()
        let refresher = TokenRefresher(api: authAPI, tokenStore: tokenStore)
        self.tokenStore = tokenStore
        self.authAPI = authAPI
        self.apiClient = APIClient(tokenStore: tokenStore, refresher: refresher)
        // Refresh rejected anywhere → one forced logout
        apiClient.onSessionExpired = { [weak self] in
            self?.logout(reason: "Your session expired. Please log in again.")
        }
    }

    // MARK: - 1. Launch: auto-login

    func restoreSession() {
        tokenStore.clearIfFreshInstall()
        guard tokenStore.tokens != nil else {
            print("SESSION: no tokens → logged out")
            state = .loggedOut
            return
        }
        print("SESSION: tokens found → checking /auth/me")
        apiClient.get("/auth/me") { [weak self] (result: Result<User, NetworkError>) in
            guard let self = self else { return }
            switch result {
            case .success(let user):
                self.setLoggedIn(user)
            case .failure(.noConnection):
                // Offline → trust Keychain, use cached user
                self.user = self.loadCachedUser()
                self.state = .loggedIn
            case .failure:
                // Refresh rejected → onSessionExpired already logged out
                if self.state == .checking {
                    self.state = .loggedOut
                }
            }
        }
    }

    // MARK: - 2. Login

    func login(username: String, password: String, completion: @escaping (Result<Void, AuthError>) -> Void) {
        authAPI.login(username: username, password: password) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                self.tokenStore.save(response.tokens)
                self.expiryMessage = nil
                self.setLoggedIn(response.user)
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - 3. Logout — ONE function for manual + forced

    func logout(reason: String?) {
        // Many 401 waiters can call this → run once
        guard state != .loggedOut else { return }
        print("SESSION: logout (\(reason ?? "manual"))")
        URLSession.shared.getAllTasks { tasks in
            for task in tasks { task.cancel() }
        }
        tokenStore.clear()
        URLCache.shared.removeAllCachedResponses()
        UserDefaults.standard.removeObject(forKey: userKey)
        user = nil
        expiryMessage = reason
        state = .loggedOut
    }

    // MARK: - Debug

    func expireAccessToken() {
        tokenStore.expireAccessToken()
    }

    // MARK: - Helpers

    private func setLoggedIn(_ user: User) {
        self.user = user
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: userKey)
        }
        state = .loggedIn
        print("SESSION: logged in as \(user.username)")
    }

    private func loadCachedUser() -> User? {
        guard let data = UserDefaults.standard.data(forKey: userKey) else { return nil }
        return try? JSONDecoder().decode(User.self, from: data)
    }
}
