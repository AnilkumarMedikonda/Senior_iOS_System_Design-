//
//  TokenRefresher.swift
//  AuthSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation

final class TokenRefresher {
    private let api: AuthAPI
    private let tokenStore: TokenStore
    private let queue = DispatchQueue(label: "auth.refresh.queue")
    private var isRefreshing = false
    private var waiters: [(Result<Void, AuthError>) -> Void] = []

    init(api: AuthAPI, tokenStore: TokenStore) {
        self.api = api
        self.tokenStore = tokenStore
    }

    /// usedToken = the access token the failed request was sent with
    func refresh(usedToken: String?, completion: @escaping (Result<Void, AuthError>) -> Void) {
        queue.async {
            // 1. Already refreshed by someone else → just retry
            if let current = self.tokenStore.tokens?.accessToken, current != usedToken, !self.isRefreshing {
                print("REFRESHER: token already new → retry without refresh")
                DispatchQueue.main.async { completion(.success(())) }
                return
            }
            // 2. Join the waiting list
            self.waiters.append(completion)
            if self.isRefreshing {
                print("REFRESHER: refresh in progress → waiting (\(self.waiters.count) waiters)")
                return
            }
            // 3. First caller → start ONE refresh
            guard let refreshToken = self.tokenStore.tokens?.refreshToken else {
                self.finish(.failure(.noRefreshToken))
                return
            }
            self.isRefreshing = true
            print("REFRESHER: starting refresh")
            self.api.refresh(refreshToken) { result in
                self.queue.async {
                    switch result {
                    case .success(let tokens):
                        self.tokenStore.save(tokens)
                        self.finish(.success(()))
                    case .failure(let error):
                        self.finish(.failure(error))
                    }
                }
            }
        }
    }

    // Runs on queue
    private func finish(_ result: Result<Void, AuthError>) {
        let list = waiters
        waiters = []
        isRefreshing = false
        print("REFRESHER: done → notifying \(list.count) waiters")
        for waiter in list {
            DispatchQueue.main.async { waiter(result) }
        }
    }
}
