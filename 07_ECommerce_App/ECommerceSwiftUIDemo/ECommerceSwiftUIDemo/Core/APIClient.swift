//
//  APIClient.swift
//  ECommerceSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation

enum NetworkError: Error {
    case invalidURL
    case noConnection
    case server(statusCode: Int)
    case decoding
    case cancelled
    case unknown
}

final class APIClient {
    private let baseURL = "https://dummyjson.com"
    private let session: URLSession

    init() {
        // HTTP cache: honors Cache-Control / ETag from the server
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(memoryCapacity: 20 * 1024 * 1024, diskCapacity: 100 * 1024 * 1024)
        config.requestCachePolicy = .useProtocolCachePolicy
        self.session = URLSession(configuration: config)
    }

    @discardableResult
    func get<T: Decodable>(_ path: String, query: [URLQueryItem] = [], completion: @escaping (Result<T, NetworkError>) -> Void) -> URLSessionDataTask? {
        var components = URLComponents(string: baseURL + path)
        if !query.isEmpty {
            components?.queryItems = query
        }
        guard let url = components?.url else {
            completion(.failure(.invalidURL))
            return nil
        }
        print("API: GET \(url.absoluteString)")
        let task = session.dataTask(with: url) { data, response, error in
            let result: Result<T, NetworkError> = self.map(data, response, error)
            DispatchQueue.main.async {
                completion(result)
            }
        }
        task.resume()
        return task
    }

    private func map<T: Decodable>(_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Result<T, NetworkError> {
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
        guard (200...299).contains(http.statusCode) else {
            return .failure(.server(statusCode: http.statusCode))
        }
        do {
            return .success(try JSONDecoder().decode(T.self, from: data))
        } catch {
            return .failure(.decoding)
        }
    }
}
