//
//  RemoteImageView.swift
//  ImageCacheSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import SwiftUI

struct RemoteImageView: View {
    @State private var viewModel: RemoteImageViewModel
    @Environment(\.displayScale) private var displayScale
    private let size: CGFloat

    init(url: URL, size: CGFloat) {
        _viewModel = State(initialValue: RemoteImageViewModel(url: url))
        self.size = size
    }

    var body: some View {
        ZStack {
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if viewModel.didFail {
                Color.gray.opacity(0.2)
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            } else {
                Color.gray.opacity(0.2)
                ProgressView()
            }
        }
        .frame(width: size, height: size)
        .clipped()
        .onAppear {
            viewModel.load(maxPixel: size * displayScale)
        }
        .onDisappear {
            viewModel.cancel()
        }
    }
}
