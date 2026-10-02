//
//  FakeCommerceServer.swift
//  ECommerceSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation

enum ServerError: Error, Equatable {
    case offline
    case timeout
    case priceChanged(CartTotals)
}

final class FakeCommerceServer {
    // Debug switches (toggled from the UI)
    var isOffline = false
    var failNextOrderWithTimeout = false

    private var priceBook: [Int: Money] = [:]      // server is the price truth
    private var ordersByKey: [UUID: Order] = [:]   // idempotency store
    private(set) var orders: [Order] = []
    private let latency = 0.6

    // MARK: - Price book

    func register(_ product: Product) {
        if priceBook[product.id] == nil {
            priceBook[product.id] = product.money
        }
    }

    func raisePrices() {
        // Sale ended → every price +10%
        for (id, price) in priceBook {
            priceBook[id] = Money(amount: price.amount * 110 / 100)
        }
        print("SERVER: prices raised 10%")
    }

    // MARK: - POST /cart/price

    func priceCart(_ items: [CartItem], completion: @escaping (Result<CartTotals, ServerError>) -> Void) {
        respond(completion) {
            .success(self.calculate(items))
        }
    }

    // MARK: - POST /checkout/validate

    func validate(_ items: [CartItem], expectedTotal: Money, completion: @escaping (Result<CartTotals, ServerError>) -> Void) {
        respond(completion) {
            let fresh = self.calculate(items)
            if fresh.total != expectedTotal {
                print("SERVER: validate → price changed \(expectedTotal.formatted) → \(fresh.total.formatted)")
                return .failure(.priceChanged(fresh))
            }
            return .success(fresh)
        }
    }

    // MARK: - POST /orders (idempotent)

    func placeOrder(_ items: [CartItem], key: UUID, completion: @escaping (Result<Order, ServerError>) -> Void) {
        respond(completion) {
            // 1. Same key → same order, no double charge
            if let existing = self.ordersByKey[key] {
                print("SERVER: duplicate key → returning existing order \(existing.id)")
                return .success(existing)
            }
            // 2. Create order
            let order = Order(id: "ORD-\(Int.random(in: 1000...9999))", items: items, total: self.calculate(items).total, createdAt: Date())
            self.ordersByKey[key] = order
            self.orders.insert(order, at: 0)
            print("SERVER: order created \(order.id) \(order.total.formatted)")
            // 3. Simulate: order created, but response lost
            if self.failNextOrderWithTimeout {
                self.failNextOrderWithTimeout = false
                print("SERVER: response lost (timeout)")
                return .failure(.timeout)
            }
            return .success(order)
        }
    }

    // MARK: - Helpers

    private func calculate(_ items: [CartItem]) -> CartTotals {
        var lines: [Int: Money] = [:]
        var subtotal = Money(amount: 0)
        for item in items {
            if let price = priceBook[item.id] {
                lines[item.id] = price
                subtotal = subtotal + price * item.quantity
            }
        }
        // Free delivery over $50
        let delivery = subtotal.amount >= 5000 || items.isEmpty ? Money(amount: 0) : Money(amount: 499)
        return CartTotals(lines: lines, subtotal: subtotal, delivery: delivery, total: subtotal + delivery)
    }

    private func respond<T>(_ completion: @escaping (Result<T, ServerError>) -> Void, work: @escaping () -> Result<T, ServerError>) {
        DispatchQueue.main.asyncAfter(deadline: .now() + latency) {
            if self.isOffline {
                completion(.failure(.offline))
                return
            }
            completion(work())
        }
    }
}
