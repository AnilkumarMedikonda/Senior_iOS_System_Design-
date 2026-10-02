//
//  Product.swift
//  PaginationSearchSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation

struct Product: Decodable, Identifiable {
    let id: Int
    let title: String
    let price: Double
    let category: String
}

struct ProductPage: Decodable {
    let products: [Product]
    let total: Int
    let skip: Int
    let limit: Int
}

enum ListState: Equatable {
    case idle
    case loading            // first page
    case loaded
    case empty
    case failed(String)
}

enum FooterState: Equatable {
    case none
    case loadingMore        // next page
    case failed             // retry button
    case endReached         // no more results
}
