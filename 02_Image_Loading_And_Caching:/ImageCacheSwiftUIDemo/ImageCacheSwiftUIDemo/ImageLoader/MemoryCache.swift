//
//  MemoryCache.swift
//  ImageCacheSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import UIKit

final class MemoryCache {
    private let cache = NSCache<NSString, UIImage>()

    init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024
    }

    func image(for key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }

    func insert(_ image: UIImage, for key: String) {
        let pixels = image.size.width * image.scale * image.size.height * image.scale
        cache.setObject(image, forKey: key as NSString, cost: Int(pixels * 4))
    }

    func removeAll() {
        cache.removeAllObjects()
    }
}
