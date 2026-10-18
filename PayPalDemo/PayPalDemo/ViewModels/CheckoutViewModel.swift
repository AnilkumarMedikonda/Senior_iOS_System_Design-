//
//  CheckoutViewModel.swift
//  PayPalDemo
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
    @Published private(set) var isPaying = false
    @Published var alertMessage: String?

    private let payPalService: PayPalServiceProtocol

    // Inject service (fake in tests)
    init(payPalService: PayPalServiceProtocol = PayPalService()) {
        self.payPalService = payPalService
    }

    var total: Decimal { cart.reduce(0) { $0 + $1.price } }
    var isCartEmpty: Bool { cart.isEmpty }

    // Add item
    func add(_ product: Product) { cart.append(product) }

    // Empty cart
    func clearCart() { cart.removeAll() }

    // Start PayPal and show result
    func payPalTapped() {
        guard !cart.isEmpty, !isPaying else { return }
        isPaying = true
        Task {
            let result = await payPalService.pay(total: total)
            isPaying = false
            alertMessage = result.message
            if result == .success { cart.removeAll() }
        }
    }

    // PayPal return URL → service
    func handleReturnURL(_ url: URL) {
        payPalService.handleReturnURL(url)
    }
}
