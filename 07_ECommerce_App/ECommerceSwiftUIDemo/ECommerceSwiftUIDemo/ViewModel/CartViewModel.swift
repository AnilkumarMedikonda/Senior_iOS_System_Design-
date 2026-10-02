//
//  CartViewModel.swift
//  ECommerceSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation
import Observation

@Observable
final class CartViewModel {
    private(set) var items: [CartItem] = []
    private(set) var totals: CartTotals?
    private(set) var isPricing = false
    private(set) var errorMessage: String?
    private(set) var count = 0
    private let cart: CartRepository
    private let router: AppRouter

    init(cart: CartRepository, router: AppRouter) {
        self.cart = cart
        self.router = router
        cart.onChange = { [weak self] in
            self?.sync()
        }
        sync()
        cart.refreshTotals()       // prices may have changed since last launch
    }

    func increment(_ item: CartItem) {
        cart.setQuantity(item.id, to: item.quantity + 1)
    }

    func decrement(_ item: CartItem) {
        cart.setQuantity(item.id, to: item.quantity - 1)
    }

    func unitPrice(_ item: CartItem) -> Money? {
        if let totals = totals {
            return totals.lines[item.id]
        } else {
            return nil
        }
    }

    var canCheckout: Bool {
        return !items.isEmpty && totals != nil && !isPricing
    }

    func checkout() {
        guard canCheckout else { return }
        router.showCheckout()
    }

    private func sync() {
        items = cart.items
        totals = cart.totals
        isPricing = cart.isPricing
        errorMessage = cart.pricingError
        count = cart.count
    }
}
