//
//  PageCache.swift
//  PaginationSearchSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation

final class PageCache {
    private struct Entry {
        let page: ProductPage
        let savedAt: Date
    }

    private var storage: [String: Entry] = [:]
    private let ttl: TimeInterval = 5 * 60

    func page(query: String, skip: Int) -> ProductPage? {
        let key = makeKey(query, skip)
        guard let entry = storage[key] else { return nil }
        // TTL expired → drop and miss
        if Date().timeIntervalSince(entry.savedAt) > ttl {
            storage[key] = nil
            print("CACHE: expired \(key)")
            return nil
        }
        print("CACHE: hit \(key)")
        return entry.page
    }

    func save(_ page: ProductPage, query: String, skip: Int) {
        storage[makeKey(query, skip)] = Entry(page: page, savedAt: Date())
    }

    func removeAll() {
        storage.removeAll()
        print("CACHE: cleared")
    }

    private func makeKey(_ query: String, _ skip: Int) -> String {
        return "\(query.lowercased())|\(skip)"
    }
}
