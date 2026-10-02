//
//  ProductListViewModel.swift
//  PaginationSearchSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation
import Observation

@Observable
final class ProductListViewModel {
    private(set) var items: [Product] = []
    private(set) var listState: ListState = .idle
    private(set) var footer: FooterState = .none
    var searchText = "" {
        didSet { searchTextChanged() }
    }

    private let repository: ProductRepository
    private let pageSize = 20
    private let threshold = 5
    private var activeQuery = ""
    private var nextSkip = 0
    private var total = 0
    private var isLoading = false
    private var seenIDs: Set<Int> = []
    private var generation = 0
    private var currentTask: URLSessionDataTask?
    private var debounceWork: DispatchWorkItem?

    init(repository: ProductRepository = ProductRepository()) {
        self.repository = repository
    }

    private var hasMore: Bool {
        return nextSkip < total
    }

    // MARK: - 1. First load

    func onAppear() {
        if listState == .idle {
            loadFirstPage()
        }
    }

    // MARK: - 2. Search — debounce

    private func searchTextChanged() {
        debounceWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.applySearch()
        }
        debounceWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
    }

    private func applySearch() {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        // Same query or 1 character → skip
        if query == activeQuery || query.count == 1 { return }
        print("SEARCH: \"\(query)\"")
        activeQuery = query
        loadFirstPage()
    }

    // MARK: - 3. Page 1 — reset + cancel old

    private func loadFirstPage() {
        currentTask?.cancel()
        generation += 1
        let requestGeneration = generation
        items = []
        seenIDs = []
        nextSkip = 0
        total = 0
        listState = .loading
        footer = .none
        isLoading = true

        currentTask = repository.fetchPage(query: activeQuery, skip: 0, limit: pageSize) { [weak self] result in
            guard let self = self, requestGeneration == self.generation else { return }   // stale → ignore
            self.isLoading = false
            self.currentTask = nil
            switch result {
            case .success(let page):
                self.append(page)
                self.listState = self.items.isEmpty ? .empty : .loaded
            case .failure(.cancelled):
                return
            case .failure(let error):
                self.listState = .failed(self.message(for: error))
            }
        }
    }

    // MARK: - 4. Next page — prefetch trigger

    func loadMoreIfNeeded(current product: Product) {
        guard let index = items.firstIndex(where: { $0.id == product.id }) else { return }
        if index >= items.count - threshold {
            loadNextPage()
        }
    }

    private func loadNextPage() {
        guard !isLoading, hasMore, listState == .loaded, footer != .failed else { return }
        let requestGeneration = generation
        isLoading = true
        footer = .loadingMore

        currentTask = repository.fetchPage(query: activeQuery, skip: nextSkip, limit: pageSize) { [weak self] result in
            guard let self = self, requestGeneration == self.generation else { return }
            self.isLoading = false
            self.currentTask = nil
            switch result {
            case .success(let page):
                self.append(page)
            case .failure(.cancelled):
                self.footer = .none
            case .failure:
                // Keep the list, show retry footer
                self.footer = .failed
            }
        }
    }

    // MARK: - 5. Retry and refresh

    func retry() {
        if case .failed = listState {
            loadFirstPage()
        } else if footer == .failed {
            footer = .none
            loadNextPage()
        }
    }

    func refresh() {
        repository.clearCache()
        loadFirstPage()
    }

    // MARK: - Helpers

    private func append(_ page: ProductPage) {
        // De-dupe by id
        for product in page.products {
            if !seenIDs.contains(product.id) {
                seenIDs.insert(product.id)
                items.append(product)
            }
        }
        total = page.total
        nextSkip = page.skip + page.products.count
        footer = hasMore ? .none : .endReached
        print("PAGE: skip \(page.skip) → \(items.count) / \(total)")
    }

    private func message(for error: NetworkError) -> String {
        switch error {
        case .noConnection:
            return "You're offline"
        default:
            return "Something went wrong"
        }
    }
}
