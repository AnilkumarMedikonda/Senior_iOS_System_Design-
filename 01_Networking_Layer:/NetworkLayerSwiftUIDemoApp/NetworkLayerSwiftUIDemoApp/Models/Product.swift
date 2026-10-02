//
//  Product.swift
//  NetworkLayerSwiftUIDemoApp
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation

struct Product: Decodable, Identifiable {
    let id: Int
    let title: String
    let price: Double
}

struct ProductsResponse: Decodable {
    let products: [Product]
}

struct ProductsEndpoint: Endpoint {
    let path = "/products"
    let method = HTTPMethod.get
}
