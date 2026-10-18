//
//  Product.swift
//  PayPalDemo
//
//  Created by Medikonda Anil kumar on 18/10/26.
//

import Foundation

// Item to buy (Decimal = exact money)
struct Product: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let emoji: String
    let price: Decimal
}

extension Product {
    // Demo menu (later from API)
    static let samples = [
        Product(name: "Coffee", emoji: "☕️", price: 4.50),
        Product(name: "Donut",  emoji: "🍩", price: 2.00),
        Product(name: "Juice",  emoji: "🧃", price: 3.25)
    ]
}
