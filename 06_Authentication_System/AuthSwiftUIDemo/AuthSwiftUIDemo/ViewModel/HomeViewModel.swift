//
//  HomeViewModel.swift
//  AuthSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation
import Observation

@Observable
final class HomeViewModel {
    private(set) var log: [String] = []
    private let session: SessionManager

    init(session: SessionManager) {
        self.session = session
    }

    // MARK: - Single call

    func loadProfile() {
        session.apiClient.get("/auth/me") { [weak self] (result: Result<User, NetworkError>) in
            switch result {
            case .success(let user):
                self?.add("✅ /auth/me → \(user.firstName)")
            case .failure(let error):
                self?.add("❌ /auth/me → \(error)")
            }
        }
    }

    // MARK: - 5 parallel calls → must trigger ONE refresh

    func fireParallelRequests() {
        add("— Firing 5 requests —")
        let paths = [
            "/auth/me",
            "/auth/products?limit=1",
            "/auth/posts?limit=1",
            "/auth/todos?limit=1",
            "/auth/recipes?limit=1"
        ]
        for path in paths {
            session.apiClient.send(path, isRetry: false) { [weak self] result in
                switch result {
                case .success:
                    self?.add("✅ \(path)")
                case .failure(let error):
                    self?.add("❌ \(path) → \(error)")
                }
            }
        }
    }

    // MARK: - Debug + logout

    func expireToken() {
        session.expireAccessToken()
        add("⏱ Access token expired (debug)")
    }

    func logout() {
        session.logout(reason: nil)
    }

    private func add(_ line: String) {
        log.insert(line, at: 0)
    }
}
