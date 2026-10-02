//
//  APIClient.swift
//  AuthSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation

final class APIClient {
    private let baseURL = "https://dummyjson.com"
    private let session: URLSession
    private let tokenStore: TokenStore
    private let refresher: TokenRefresher
    var onSessionExpired: (() -> Void)?

    init(tokenStore: TokenStore, refresher: TokenRefresher, session: URLSession = .shared) {
        self.tokenStore = tokenStore
        self.refresher = refresher
        self.session = session
    }

    // MARK: - Decoded GET

    func get<T: Decodable>(_ path: String, completion: @escaping (Result<T, NetworkError>) -> Void) {
        send(path, isRetry: false) { result in
            switch result {
            case .success(let data):
                if let model = try? JSONDecoder().decode(T.self, from: data) {
                    completion(.success(model))
                } else {
                    completion(.failure(.decoding))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Core: Bearer token → 401 → refresh → retry once

    func send(_ path: String, isRetry: Bool, completion: @escaping (Result<Data, NetworkError>) -> Void) {
        guard let url = URL(string: baseURL + path) else {
            completion(.failure(.unknown))
            return
        }
        // 1. Attach access token
        var request = URLRequest(url: url)
        let usedToken = tokenStore.tokens?.accessToken
        if let token = usedToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        print("API: GET \(path)\(isRetry ? " (retry)" : "")")

        // 2. Send
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                let result = self.map(data, response, error)
                // 3. 401 on first try → refresh, then retry once
                if case .failure(.unauthorized) = result, !isRetry {
                    print("API: 401 on \(path) → refresh")
                    self.refresher.refresh(usedToken: usedToken) { refreshResult in
                        switch refreshResult {
                        case .success:
                            self.send(path, isRetry: true, completion: completion)
                        case .failure(.network):
                            // Offline → keep session
                            completion(.failure(.noConnection))
                        case .failure:
                            // Refresh rejected → logout
                            self.onSessionExpired?()
                            completion(.failure(.unauthorized))
                        }
                    }
                    return
                }
                completion(result)
            }
        }.resume()
    }

    // MARK: - Map response

    private func map(_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Result<Data, NetworkError> {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .cancelled:
                return .failure(.cancelled)
            case .notConnectedToInternet, .timedOut:
                return .failure(.noConnection)
            default:
                return .failure(.unknown)
            }
        }
        guard let http = response as? HTTPURLResponse, let data = data else {
            return .failure(.unknown)
        }
        switch http.statusCode {
        case 200...299:
            return .success(data)
        case 401, 403:
            return .failure(.unauthorized)
        default:
            return .failure(.server(statusCode: http.statusCode))
        }
    }
}
