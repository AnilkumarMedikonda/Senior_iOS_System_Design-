//
//  CatalogViewModel.swift
//  ECommerceSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation
import Observation

@Observable
final class CatalogViewModel {
    private(set) var products: [Product] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private let catalog: CatalogRepository
    private var pages: [Int: [Product]] = [:]      // skip → products
    private var total = 0
    private let pageSize = 20

    init(catalog: CatalogRepository) {
        self.catalog = catalog
    }

    private var nextSkip: Int {
        return products.count
    }

    var hasMore: Bool {
        return total == 0 || products.count < total
    }

    func loadFirstPage() {
        guard products.isEmpty else { return }
        load(skip: 0)
    }

    func loadMoreIfNeeded(current: Product) {
        guard let last = products.last, last.id == current.id, hasMore, !isLoading else { return }
        load(skip: nextSkip)
    }

    func refresh() {
        catalog.clearCache()
        pages = [:]
        products = []
        total = 0
        load(skip: 0)
    }

    private func load(skip: Int) {
        isLoading = true
        errorMessage = nil
        catalog.fetchPage(skip: skip, limit: pageSize) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            switch result {
            case .success(let page):
                // Cached + fresh both land here → replace that page
                self.pages[page.skip] = page.products
                self.total = page.total
                self.rebuild()
            case .failure:
                self.errorMessage = "Couldn't load products"
            }
        }
    }

    private func rebuild() {
        var all: [Product] = []
        for skip in pages.keys.sorted() {
            if let list = pages[skip] {
                all.append(contentsOf: list)
            }
        }
        products = all
    }
}

