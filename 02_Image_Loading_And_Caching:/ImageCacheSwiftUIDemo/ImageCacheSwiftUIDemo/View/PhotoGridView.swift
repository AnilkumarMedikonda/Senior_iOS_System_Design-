//
//  PhotoGridView.swift
//  ImageCacheSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import SwiftUI

struct PhotoGridView: View {
    @State private var viewModel = PhotoGridViewModel()
    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 8)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(viewModel.photos) { photo in
                        RemoteImageView(url: photo.url, size: 110)
                    }
                }
                .padding()
            }
            .navigationTitle("Photos")
            .toolbar {
                Button("Clear Cache") {
                    ImageLoader.shared.clearAll()
                }
            }
        }
        .onAppear {
            viewModel.loadPhotos()
        }
    }
}
