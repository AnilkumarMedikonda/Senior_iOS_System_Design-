//
//  CheckoutViewModel.swift
//  ApplePayDemo
//
//  Created by Medikonda Anil kumar on 18/10/26.
//

import Foundation
import Combine

// Screen state + logic
@MainActor
final class CheckoutViewModel: ObservableObject {

    @Published private(set) var products: [Product] = Product.samples
    @Published private(set) var cart: [Product] = []
    @Published private(set) var isPaying = false      // blocks double tap
    @Published var alertMessage: String?

    private let paymentService: ApplePayServiceProtocol

    // Inject service (fake in tests)
    init(paymentService: ApplePayServiceProtocol = ApplePayService()) {
        self.paymentService = paymentService
    }

    var total: Decimal { cart.reduce(0) { $0 + $1.price } }
    var canPay: Bool { paymentService.canPay }
    var isCartEmpty: Bool { cart.isEmpty }

    // Add item to cart
    func add(_ product: Product) {
        cart.append(product)
    }

    // Empty the cart
    func clearCart() {
        cart.removeAll()
    }

    // Start Apple Pay and handle result
    func payTapped() {
        guard !cart.isEmpty, !isPaying else { return }
        isPaying = true

        paymentService.pay(items: cart, total: total) { [weak self] result in
            guard let self else { return }
            isPaying = false
            alertMessage = result.message
            if result == .success { cart.removeAll() }
        }
    }
}
