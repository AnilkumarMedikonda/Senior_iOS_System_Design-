//
//  ProductListViewModel.swift
//  NetworkLayerSwiftUIDemoApp
//
//  Created by Medikonda Anil kumar on 02/10/26.
//


import Foundation
import Observation

enum ProductsState {
    case loading
    case loaded([Product])
    case failed(String)
}

@Observable
final class ProductListViewModel {
    private(set) var state: ProductsState = .loading
    private let repository: ProductRepositoryProtocol

    init() {
        self.repository = ProductRepository()
    }

    init(repository: ProductRepositoryProtocol) {
        self.repository = repository
    }

    func loadProducts() {
        state = .loading
        repository.fetchProducts { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let products):
                    self.state = .loaded(products)
                case .failure(.cancelled):
                    return
                case .failure(let error):
                    self.state = .failed(self.message(for: error))
                }
            }
        }
    }

    private func message(for error: NetworkError) -> String {
        switch error {
        case .noConnection:
            return "You're offline"
        case .unauthorized:
            return "Session expired"
        default:
            return "Something went wrong"
        }
    }
}
