//
//  ProductRepository.swift
//  PaginationSearchSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation

final class ProductRepository {
    private let client: APIClient
    private let cache: PageCache

    init(client: APIClient = APIClient(), cache: PageCache = PageCache()) {
        self.client = client
        self.cache = cache
    }

    @discardableResult
    func fetchPage(query: String, skip: Int, limit: Int, completion: @escaping (Result<ProductPage, NetworkError>) -> Void) -> URLSessionDataTask? {
        // 1. Cache first
        if let cached = cache.page(query: query, skip: skip) {
            completion(.success(cached))
            return nil
        }
        // 2. Pick endpoint — list or search
        let path: String
        var items = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "skip", value: "\(skip)"),
            URLQueryItem(name: "select", value: "title,price,category")
        ]
        if query.isEmpty {
            path = "/products"
        } else {
            path = "/products/search"
            items.append(URLQueryItem(name: "q", value: query))
        }
        // 3. Network → save to cache
        return client.get(path, queryItems: items) { [weak self] (result: Result<ProductPage, NetworkError>) in
            if case .success(let page) = result {
                self?.cache.save(page, query: query, skip: skip)
            }
            completion(result)
        }
    }

    func clearCache() {
        cache.removeAll()
    }
}
