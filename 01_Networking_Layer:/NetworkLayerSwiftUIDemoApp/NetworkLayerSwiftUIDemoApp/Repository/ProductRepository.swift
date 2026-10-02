//
//  ProductRepository.swift
//  NetworkLayerSwiftUIDemoApp
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation

protocol ProductRepositoryProtocol {
    func fetchProducts(completion: @escaping (Result<[Product], NetworkError>) -> Void)
}

final class ProductRepository: ProductRepositoryProtocol {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    convenience init() {
        self.init(client: APIClient())
    }

    func fetchProducts(completion: @escaping (Result<[Product], NetworkError>) -> Void) {
        client.send(ProductsEndpoint()) { (result: Result<ProductsResponse, NetworkError>) in
            switch result {
            case .success(let response):
                completion(.success(response.products))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
