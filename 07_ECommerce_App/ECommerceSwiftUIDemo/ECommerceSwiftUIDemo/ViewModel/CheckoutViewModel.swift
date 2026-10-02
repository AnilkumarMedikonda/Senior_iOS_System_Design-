//
//  CheckoutViewModel.swift
//  ECommerceSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation
import Observation

@Observable
final class CheckoutViewModel {
    private(set) var step: CheckoutStep = .address
    var name = "Anil Kumar"
    var street = "12 MG Road"
    var city = "Bengaluru"
    private(set) var expectedTotal: Money?
    private let cart: CartRepository
    private let server: FakeCommerceServer
    private let router: AppRouter
    private var idempotencyKey: UUID?

    init(cart: CartRepository, server: FakeCommerceServer, router: AppRouter) {
        self.cart = cart
        self.server = server
        self.router = router
    }

    var items: [CartItem] {
        return cart.items
    }

    var canContinue: Bool {
        return !name.isEmpty && !street.isEmpty && !city.isEmpty
    }

    // MARK: - 1. Address → Review (key created ONCE here)

    func continueToReview() {
        guard canContinue, let totals = cart.totals else { return }
        if idempotencyKey == nil {
            idempotencyKey = UUID()
        }
        expectedTotal = totals.total
        step = .review
        print("CHECKOUT: review, key = \(idempotencyKey!.uuidString.prefix(8))")
    }

    // MARK: - 2. Place order: validate → place

    func placeOrder() {
        // Double-tap guard: only from review or failed
        switch step {
        case .review, .failed:
            break
        default:
            return
        }
        guard let key = idempotencyKey, let expected = expectedTotal else { return }
        step = .placing
        let snapshot = cart.items

        // 2a. Validate price + stock right before paying
        server.validate(snapshot, expectedTotal: expected) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.submit(snapshot, key: key)
            case .failure(.priceChanged(let fresh)):
                self.cart.applyServerTotals(fresh)
                self.expectedTotal = fresh.total
                self.step = .priceChanged("Total changed from \(expected.formatted) to \(fresh.total.formatted)")
            case .failure(.offline):
                self.step = .failed("You're offline. Your order was not placed.")
            case .failure:
                self.step = .failed("Couldn't verify your cart. Try again.")
            }
        }
    }

    // 2b. Same key on every retry → never two orders
    private func submit(_ items: [CartItem], key: UUID) {
        print("CHECKOUT: placing order with key \(key.uuidString.prefix(8))")
        server.placeOrder(items, key: key) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let order):
                self.cart.clear()
                self.idempotencyKey = nil
                self.step = .success(orderID: order.id)
            case .failure(.timeout):
                // Unknown state → keep the key, retry is safe
                self.step = .failed("Connection lost. Tap Retry — you won't be charged twice.")
            case .failure:
                self.step = .failed("Order not placed. Try again.")
            }
        }
    }

    // MARK: - 3. User actions

    func confirmNewPrice() {
        step = .review
    }

    func retry() {
        placeOrder()
    }

    func finish() {
        step = .address
        router.showOrders()
    }

    // MARK: - Debug switches

    func debugRaisePrices() {
        server.raisePrices()
    }

    func debugFailNextWithTimeout() {
        server.failNextOrderWithTimeout = true
        print("DEBUG: next order response will be lost")
    }

    func debugToggleOffline() {
        server.isOffline.toggle()
        print("DEBUG: offline = \(server.isOffline)")
    }
}

// MARK: - Orders

@Observable
final class OrdersViewModel {
    private(set) var orders: [Order] = []
    private let server: FakeCommerceServer

    init(server: FakeCommerceServer) {
        self.server = server
    }

    func load() {
        orders = server.orders
    }
}
