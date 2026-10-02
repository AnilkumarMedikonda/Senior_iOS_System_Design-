//
//  ImageCacheSwiftUIDemoApp.swift
//  ImageCacheSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import SwiftUI

@main
struct ImageCacheSwiftUIDemoApp: App {
    init() {
        ImageLoader.shared.cleanUpDisk()
    }

    var body: some Scene {
        WindowGroup {
            PhotoGridView()
        }
    }
}
