//
//  ProductListView.swift
//  NetworkLayerSwiftUIDemoApp
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import SwiftUI

struct ProductListView: View {
    @State private var viewModel = ProductListViewModel()

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Products")
        }
        .onAppear {
            viewModel.loadProducts()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case .loaded(let products):
            List(products) { product in
                HStack {
                    Text(product.title)
                    Spacer()
                    Text("$\(product.price, specifier: "%.2f")")
                }
            }
        case .failed(let message):
            VStack(spacing: 12) {
                Text(message)
                Button("Retry") {
                    viewModel.loadProducts()
                }
            }
        }
    }
}
