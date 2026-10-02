//
//  PhotoGridViewModel.swift
//  ImageCacheSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation
import Observation

@Observable
final class PhotoGridViewModel {
    private(set) var photos: [Photo] = []

    func loadPhotos() {
        var items: [Photo] = []
        for index in 1...100 {
            if let url = URL(string: "https://picsum.photos/id/\(index)/800/800") {
                items.append(Photo(id: index, url: url))
            }
        }
        photos = items
    }
}
