//
//  AuthAPI.swift
//  AuthSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation

final class AuthAPI {
    private let baseURL = "https://dummyjson.com/auth"
    private let session: URLSession
    private let tokenLifetimeMinutes = 1      // short on purpose → see refresh in action

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - POST /auth/login

    func login(username: String, password: String, completion: @escaping (Result<LoginResponse, AuthError>) -> Void) {
        let body: [String: Any] = [
            "username": username,
            "password": password,
            "expiresInMins": tokenLifetimeMinutes
        ]
        post("/login", body: body) { data, status, error in
            if error != nil {
                completion(.failure(.network))
                return
            }
            guard status == 200, let data = data,
                  let response = try? JSONDecoder().decode(LoginResponse.self, from: data) else {
                completion(.failure(.invalidCredentials))
                return
            }
            print("AUTH API: login ok → \(response.username)")
            completion(.success(response))
        }
    }

    // MARK: - POST /auth/refresh

    func refresh(_ refreshToken: String, completion: @escaping (Result<AuthTokens, AuthError>) -> Void) {
        let body: [String: Any] = [
            "refreshToken": refreshToken,
            "expiresInMins": tokenLifetimeMinutes
        ]
        post("/refresh", body: body) { data, status, error in
            // Offline → stay logged in
            if error != nil {
                completion(.failure(.network))
                return
            }
            // Refresh token rejected → logout
            guard status == 200, let data = data,
                  let tokens = try? JSONDecoder().decode(AuthTokens.self, from: data) else {
                print("AUTH API: refresh rejected (\(status))")
                completion(.failure(.refreshRejected))
                return
            }
            print("AUTH API: refresh ok → new tokens")
            completion(.success(tokens))
        }
    }

    // MARK: - Shared POST (no Authorization header)

    private func post(_ path: String, body: [String: Any], completion: @escaping (Data?, Int, Error?) -> Void) {
        guard let url = URL(string: baseURL + path) else {
            completion(nil, 0, URLError(.badURL))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        session.dataTask(with: request) { data, response, error in
            let status: Int
            if let http = response as? HTTPURLResponse {
                status = http.statusCode
            } else {
                status = 0
            }
            DispatchQueue.main.async {
                completion(data, status, error)
            }
        }.resume()
    }
}
