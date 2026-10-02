//
//  APIClient.swift
//  NetworkLayerSwiftUIDemoApp
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation

final class APIClient {
    private let baseURL = "https://dummyjson.com"
    private let http: HTTPClient

    init(http: HTTPClient) {
        self.http = http
    }

    convenience init() {
        self.init(http: URLSession.shared)
    }

    func send<T: Decodable>(_ endpoint: Endpoint, completion: @escaping (Result<T, NetworkError>) -> Void) {
        // 1. Build request
        guard let url = URL(string: baseURL + endpoint.path) else {
            completion(.failure(.invalidURL))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        // 2. Send
        http.send(request) { data, response, error in
            if let urlError = error as? URLError {
                completion(.failure(self.mapURLError(urlError)))
                return
            }
            if error != nil {
                completion(.failure(.unknown))
                return
            }

            // 3. Validate status
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.unknown))
                return
            }
            switch httpResponse.statusCode {
            case 200...299:
                break
            case 401:
                completion(.failure(.unauthorized))
                return
            default:
                completion(.failure(.server(statusCode: httpResponse.statusCode)))
                return
            }

            // 4. Decode
            guard let data = data else {
                completion(.failure(.unknown))
                return
            }
            do {
                let model = try JSONDecoder().decode(T.self, from: data)
                completion(.success(model))
            } catch {
                completion(.failure(.decoding))
            }
        }
    }

    private func mapURLError(_ error: URLError) -> NetworkError {
        switch error.code {
        case .notConnectedToInternet, .timedOut:
            return .noConnection
        case .cancelled:
            return .cancelled
        default:
            return .unknown
        }
    }
}
