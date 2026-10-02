//
//  ImageLoader.swift
//  ImageCacheSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import UIKit

final class ImageLoader {
    static let shared = ImageLoader()
    private let memoryCache = MemoryCache()
    private let diskCache = DiskCache()
    private let queue = DispatchQueue(label: "image.loader.queue")
    private var tasks: [URL: URLSessionDataTask] = [:]
    private var waiters: [URL: [UUID: Waiter]] = [:]

    private struct Waiter {
        let maxPixel: CGFloat
        let completion: (UIImage?) -> Void
    }

    @discardableResult
    func load(_ url: URL, maxPixel: CGFloat, completion: @escaping (UIImage?) -> Void) -> UUID {
        let id = UUID()
        // 1. Memory
        if let image = memoryCache.image(for: cacheKey(url, maxPixel)) {
            completion(image)
            return id
        }
        queue.async {
            // 2. Disk
            if let data = self.diskCache.data(for: url) {
                let image = ImageDownsampler.downsample(data, maxPixel: maxPixel)
                self.finish(url, maxPixel, image, completion)
                return
            }
            // 3. Network — join an in-flight request if one exists
            let waiter = Waiter(maxPixel: maxPixel, completion: completion)
            if var list = self.waiters[url] {
                list[id] = waiter
                self.waiters[url] = list
                return
            }
            self.waiters[url] = [id: waiter]
            let task = URLSession.shared.dataTask(with: url) { data, response, _ in
                self.queue.async {
                    self.handleDownload(url, data, response)
                }
            }
            self.tasks[url] = task
            task.resume()
        }
        return id
    }

    func cancel(_ url: URL, id: UUID) {
        queue.async {
            guard var list = self.waiters[url] else { return }
            list[id] = nil
            if list.isEmpty {
                self.tasks[url]?.cancel()
                self.tasks[url] = nil
                self.waiters[url] = nil
            } else {
                self.waiters[url] = list
            }
        }
    }

    func clearAll() {
        memoryCache.removeAll()
        queue.async {
            self.diskCache.removeAll()
        }
    }

    func cleanUpDisk() {
        queue.async {
            self.diskCache.cleanUp()
        }
    }

    private func handleDownload(_ url: URL, _ data: Data?, _ response: URLResponse?) {
        let list = waiters[url]
        waiters[url] = nil
        tasks[url] = nil
        // All waiters cancelled
        guard let list = list else { return }
        guard let data = data,
              let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            for (_, waiter) in list {
                DispatchQueue.main.async { waiter.completion(nil) }
            }
            return
        }
        diskCache.save(data, for: url)
        for (_, waiter) in list {
            let image = ImageDownsampler.downsample(data, maxPixel: waiter.maxPixel)
            finish(url, waiter.maxPixel, image, waiter.completion)
        }
    }

    private func finish(_ url: URL, _ maxPixel: CGFloat, _ image: UIImage?, _ completion: @escaping (UIImage?) -> Void) {
        if let image = image {
            memoryCache.insert(image, for: cacheKey(url, maxPixel))
        }
        DispatchQueue.main.async {
            completion(image)
        }
    }

    private func cacheKey(_ url: URL, _ maxPixel: CGFloat) -> String {
        return "\(url.absoluteString)_\(Int(maxPixel))"
    }
}
