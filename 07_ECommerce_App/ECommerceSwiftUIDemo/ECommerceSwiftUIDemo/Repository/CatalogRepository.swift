//
//  CatalogRepository.swift
//  ECommerceSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation

final class CatalogRepository {
    private struct Entry<T> {
        let value: T
        let savedAt: Date
    }

    private let client: APIClient
    private let server: FakeCommerceServer
    private var pageCache: [Int: Entry<ProductPage>] = [:]       // skip → page
    private var productCache: [Int: Entry<Product>] = [:]        // id → static detail
    private let pageTTL: TimeInterval = 5 * 60
    private let productTTL: TimeInterval = 30 * 60

    init(client: APIClient, server: FakeCommerceServer) {
        self.client = client
        self.server = server
    }

    // MARK: - Product list: stale-while-revalidate
    // completion can be called TWICE: cached first, then fresh

    func fetchPage(skip: Int, limit: Int, completion: @escaping (Result<ProductPage, NetworkError>) -> Void) {
        let cached = pageCache[skip]
        if let cached = cached {
            print("CATALOG: page \(skip) from cache")
            completion(.success(cached.value))
            // Fresh enough → no network
            if Date().timeIntervalSince(cached.savedAt) < pageTTL {
                return
            }
        }
        let query = [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "skip", value: "\(skip)"),
            URLQueryItem(name: "select", value: "title,description,price,stock,thumbnail")
        ]
        client.get("/products", query: query) { [weak self] (result: Result<ProductPage, NetworkError>) in
            guard let self = self else { return }
            switch result {
            case .success(let page):
                self.pageCache[skip] = Entry(value: page, savedAt: Date())
                for product in page.products {
                    self.productCache[product.id] = Entry(value: product, savedAt: Date())
                    self.server.register(product)
                }
                completion(.success(page))
            case .failure(let error):
                // Already showed cache → don't replace it with an error
                if cached == nil {
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - Static product detail (title, images) — cached 30 min

    func cachedProduct(_ id: Int) -> Product? {
        guard let entry = productCache[id] else { return nil }
        if Date().timeIntervalSince(entry.savedAt) > productTTL {
            return nil
        }
        return entry.value
    }

    // MARK: - Dynamic price — ALWAYS fresh from server

    func fetchFreshPrice(_ product: Product, completion: @escaping (Money?) -> Void) {
        let probe = [CartItem(id: product.id, title: product.title, quantity: 1)]
        server.priceCart(probe) { result in
            switch result {
            case .success(let totals):
                completion(totals.lines[product.id])
            case .failure:
                completion(nil)
            }
        }
    }

    // MARK: - Pull to refresh

    func clearCache() {
        pageCache.removeAll()
        print("CATALOG: cache cleared")
    }
}
