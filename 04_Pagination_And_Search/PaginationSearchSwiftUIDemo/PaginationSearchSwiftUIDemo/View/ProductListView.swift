//
//  ProductListView.swift
//  PaginationSearchSwiftUIDemo
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
                .searchable(text: $viewModel.searchText, prompt: "Search products")
        }
        .onAppear {
            viewModel.onAppear()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.listState {
        case .idle, .loading:
            ProgressView()
        case .empty:
            ContentUnavailableView.search(text: viewModel.searchText)
        case .failed(let message):
            VStack(spacing: 12) {
                Text(message)
                Button("Retry") { viewModel.retry() }
            }
        case .loaded:
            list
        }
    }

    private var list: some View {
        List {
            ForEach(viewModel.items) { product in
                row(product)
                    .onAppear {
                        viewModel.loadMoreIfNeeded(current: product)
                    }
            }
            footer
        }
        .refreshable {
            viewModel.refresh()
        }
    }

    private func row(_ product: Product) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(product.title)
                .font(.headline)
            HStack {
                Text(product.category.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("$\(product.price, specifier: "%.2f")")
                    .font(.subheadline)
            }
        }
    }

    @ViewBuilder
    private var footer: some View {
        switch viewModel.footer {
        case .none:
            EmptyView()
        case .loadingMore:
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
        case .failed:
            Button("Couldn't load more. Tap to retry") {
                viewModel.retry()
            }
        case .endReached:
            Text("No more results")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
    }
}
