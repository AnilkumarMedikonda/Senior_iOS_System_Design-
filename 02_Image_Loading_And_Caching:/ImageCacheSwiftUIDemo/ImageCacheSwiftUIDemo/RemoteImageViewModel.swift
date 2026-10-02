//
//  RemoteImageViewModel.swift
//  ImageCacheSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//


import UIKit
import Observation

@Observable
final class RemoteImageViewModel {
    private(set) var image: UIImage?
    private(set) var didFail = false
    private let url: URL
    private var requestID: UUID?

    init(url: URL) {
        self.url = url
    }

    func load(maxPixel: CGFloat) {
        guard image == nil else { return }
        didFail = false
        requestID = ImageLoader.shared.load(url, maxPixel: maxPixel) { [weak self] image in
            guard let self = self else { return }
            self.requestID = nil
            if let image = image {
                self.image = image
            } else {
                self.didFail = true
            }
        }
    }

    func cancel() {
        if let id = requestID {
            ImageLoader.shared.cancel(url, id: id)
            requestID = nil
        }
    }
}
