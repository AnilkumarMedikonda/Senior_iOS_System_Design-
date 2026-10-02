//
//  DiskCache.swift
//  ImageCacheSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation
import CryptoKit

final class DiskCache {
    private let fileManager = FileManager.default
    private let folder: URL
    private let maxAge: TimeInterval = 7 * 24 * 60 * 60
    private let maxSize = 100 * 1024 * 1024

    init() {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        folder = caches.appendingPathComponent("ImageCache")
        try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    func data(for url: URL) -> Data? {
        let file = fileURL(for: url)
        guard let data = try? Data(contentsOf: file) else { return nil }
        // Touch date for LRU
        try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: file.path)
        return data
    }

    func save(_ data: Data, for url: URL) {
        try? data.write(to: fileURL(for: url))
    }

    func removeAll() {
        try? fileManager.removeItem(at: folder)
        try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    func cleanUp() {
        let keys: [URLResourceKey] = [.contentModificationDateKey, .fileSizeKey]
        guard let files = try? fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: keys) else { return }
        var remaining: [(url: URL, date: Date, size: Int)] = []
        var totalSize = 0
        // 1. TTL — remove expired
        for file in files {
            guard let values = try? file.resourceValues(forKeys: Set(keys)),
                  let date = values.contentModificationDate,
                  let size = values.fileSize else { continue }
            if Date().timeIntervalSince(date) > maxAge {
                try? fileManager.removeItem(at: file)
            } else {
                remaining.append((file, date, size))
                totalSize += size
            }
        }
        // 2. Size limit — remove least recently used
        guard totalSize > maxSize else { return }
        remaining.sort { $0.date < $1.date }
        for item in remaining {
            if totalSize <= maxSize { break }
            try? fileManager.removeItem(at: item.url)
            totalSize -= item.size
        }
    }

    private func fileURL(for url: URL) -> URL {
        let hash = SHA256.hash(data: Data(url.absoluteString.utf8))
        let name = hash.map { String(format: "%02x", $0) }.joined()
        return folder.appendingPathComponent(name)
    }
}
