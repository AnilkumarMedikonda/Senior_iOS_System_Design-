//
//  TokenStore.swift
//  AuthSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation

final class TokenStore {
    private let keychain = KeychainStore()
    private let key = "tokens"
    private let lock = NSLock()
    private var cached: AuthTokens?

    // MARK: - Read (memory first, then Keychain)

    var tokens: AuthTokens? {
        lock.lock()
        defer { lock.unlock() }
        if let cached = cached {
            return cached
        }
        guard let data = keychain.read(key),
              let tokens = try? JSONDecoder().decode(AuthTokens.self, from: data) else { return nil }
        cached = tokens
        return tokens
    }

    // MARK: - Save both tokens together

    func save(_ tokens: AuthTokens) {
        lock.lock()
        defer { lock.unlock() }
        cached = tokens
        if let data = try? JSONEncoder().encode(tokens) {
            keychain.save(data, for: key)
        }
    }

    // MARK: - Clear on logout

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        cached = nil
        keychain.delete(key)
    }

    // MARK: - Reinstall check

    func clearIfFreshInstall() {
        let flag = "hasLaunchedBefore"
        if !UserDefaults.standard.bool(forKey: flag) {
            print("TOKENS: fresh install → clearing old Keychain tokens")
            clear()
            UserDefaults.standard.set(true, forKey: flag)
        }
    }

    // MARK: - Debug: simulate expired access token

    func expireAccessToken() {
        guard let current = tokens else { return }
        save(AuthTokens(accessToken: "expired-token", refreshToken: current.refreshToken))
        print("TOKENS: access token expired (debug)")
    }
}
