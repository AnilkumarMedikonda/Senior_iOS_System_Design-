//
//  AuthModels.swift
//  AuthSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation

// MARK: - Tokens (saved as ONE Keychain item)

struct AuthTokens: Codable {
    let accessToken: String
    let refreshToken: String
}

// MARK: - User

struct User: Codable {
    let id: Int
    let username: String
    let firstName: String
}

// MARK: - POST /auth/login response

struct LoginResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let id: Int
    let username: String
    let firstName: String

    var tokens: AuthTokens {
        return AuthTokens(accessToken: accessToken, refreshToken: refreshToken)
    }

    var user: User {
        return User(id: id, username: username, firstName: firstName)
    }
}

// MARK: - Session

enum SessionState: Equatable {
    case checking        // launch: reading Keychain
    case loggedOut
    case loggedIn
}

// MARK: - Errors

enum AuthError: Error {
    case invalidCredentials     // login 400
    case noRefreshToken
    case refreshRejected        // refresh 401/403 → logout
    case network                // offline → stay logged in
}

enum NetworkError: Error {
    case unauthorized           // 401
    case noConnection
    case server(statusCode: Int)
    case decoding
    case cancelled
    case unknown
}
