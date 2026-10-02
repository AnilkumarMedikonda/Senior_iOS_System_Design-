//
//  CatalogView.swift
//  ECommerceSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import SwiftUI

struct CatalogView: View {
    let viewModel: CatalogViewModel
    let router: AppRouter

    var body: some View {
        List {
            ForEach(viewModel.products) { product in
                Button {
                    router.showProduct(product)
                } label: {
                    ProductRow(product: product)
                }
                .buttonStyle(.plain)
                .onAppear { viewModel.loadMoreIfNeeded(current: product) }
            }
            if viewModel.isLoading {
                ProgressView().frame(maxWidth: .infinity)
            }
            if let error = viewModel.errorMessage {
                Text(error).foregroundStyle(.red)
            }
        }
        .navigationTitle("Shop")
        .refreshable { viewModel.refresh() }
        .onAppear { viewModel.loadFirstPage() }
    }
}

struct ProductRow: View {
    let product: Product

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: product.thumbnail)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(product.title).font(.headline)
                // List price is cached → for browsing only
                Text(product.money.formatted).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

struct ProductDetailView: View {
    @State private var viewModel: ProductDetailViewModel

    init(product: Product, deps: AppDependencies) {
        _viewModel = State(initialValue: ProductDetailViewModel(product: product, catalog: deps.catalog, cart: deps.cart, router: deps.router))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AsyncImage(url: URL(string: viewModel.product.thumbnail)) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Color.gray.opacity(0.2).frame(height: 250)
                }
                Text(viewModel.product.title).font(.title.bold())
                // Fresh price from server
                HStack {
                    if viewModel.isLoadingPrice {
                        ProgressView()
                        Text("Checking price…").foregroundStyle(.secondary)
                    } else if let price = viewModel.freshPrice {
                        Text(price.formatted).font(.title2.bold())
                    } else {
                        Text("Price unavailable").foregroundStyle(.red)
                    }
                }
                Text(viewModel.product.description).foregroundStyle(.secondary)
                Button("Add to Cart") { viewModel.addToCart() }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.freshPrice == nil)
                if let message = viewModel.addedMessage {
                    Button("\(message) · View Cart") { viewModel.goToCart() }
                }
            }
            .padding()
        }
        .navigationTitle("Product")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.loadPrice() }
    }
}
