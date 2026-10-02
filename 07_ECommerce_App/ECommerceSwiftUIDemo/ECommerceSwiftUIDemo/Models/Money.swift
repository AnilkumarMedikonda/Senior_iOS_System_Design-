//
//  File.swift
//  ECommerceSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation

// MARK: - Money (minor units, never Double)

struct Money: Codable, Equatable {
    let amount: Int             // cents
    let currency: String

    init(amount: Int, currency: String = "USD") {
        self.amount = amount
        self.currency = currency
    }

    init(dollars: Double) {
        self.amount = Int((dollars * 100).rounded())
        self.currency = "USD"
    }

    var formatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        let value = NSDecimalNumber(value: amount).dividing(by: 100)
        if let text = formatter.string(from: value) {
            return text
        } else {
            return "\(amount)"
        }
    }

    static func + (lhs: Money, rhs: Money) -> Money {
        return Money(amount: lhs.amount + rhs.amount, currency: lhs.currency)
    }

    static func * (lhs: Money, rhs: Int) -> Money {
        return Money(amount: lhs.amount * rhs, currency: lhs.currency)
    }
}

// MARK: - Catalog (DummyJSON shape)

struct Product: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let description: String
    let price: Double
    let stock: Int
    let thumbnail: String

    var money: Money {
        return Money(dollars: price)
    }
}

struct ProductPage: Codable {
    let products: [Product]
    let total: Int
    let skip: Int
}

// MARK: - Cart

struct CartItem: Codable, Identifiable, Equatable {
    let id: Int                 // product id
    let title: String
    var quantity: Int
}

struct CartTotals: Equatable {
    let lines: [Int: Money]     // product id → server unit price
    let subtotal: Money
    let delivery: Money
    let total: Money
}

// MARK: - Checkout + Orders

enum CheckoutStep: Equatable {
    case address
    case review
    case placing
    case priceChanged(String)
    case success(orderID: String)
    case failed(String)
}

struct Order: Codable, Identifiable {
    let id: String
    let items: [CartItem]
    let total: Money
    let createdAt: Date
}
