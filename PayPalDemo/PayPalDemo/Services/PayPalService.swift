//
//  PayPalService.swift
//  PayPalDemo
//
//  Created by Medikonda Anil kumar on 18/10/26.
//

import Foundation
import CorePayments
import PayPalPayments

// PayPal contract – fake it in tests
protocol PayPalServiceProtocol {
    func pay(total: Decimal) async -> PaymentResult
    func handleReturnURL(_ url: URL)
}

// Real PayPal checkout (SDK v3)
final class PayPalService: PayPalServiceProtocol {

    private let client: PayPalClient
    private let api: PayPalAPIProtocol

    // Return links after approve / cancel
    private let urlConfig = PayPalURLConfig(
        returnAppURL: URL(string: "https://example.com/paypaldemo/return")!,
        cancelAppURL: URL(string: "https://example.com/paypaldemo/cancel")!,
        fallbackSchemeURL: URL(string: "paypaldemo://paypal")      // matches URL Types
    )

    init(api: PayPalAPIProtocol = PayPalAPI()) {
        let config = CoreConfig(
            clientID: "YOUR_SANDBOX_CLIENT_ID",       // ⚠️ Step 1
            environment: .sandbox,
            merchantID: "YOUR_SANDBOX_MERCHANT_ID"    // ⚠️ business Account ID
        )
        self.client = PayPalClient(config: config)
        self.api = api
    }

    // Session → create order → approve → capture
    func pay(total: Decimal) async -> PaymentResult {
        client.createPayPalSession(sessionType: .checkout,   // required before start()
                                   userIdentity: nil,
                                   urlConfig: urlConfig,
                                   userAction: .payNow)
        do {
            let orderID = try await api.createOrder(amount: total)
            let approval = await approve(orderID: orderID)
            guard approval == .success else { return approval }
            return try await api.captureOrder(id: orderID) ? .success : .failed
        } catch {
            return .failed
        }
    }

    // Opens PayPal login and waits for approve / cancel
    private func approve(orderID: String) async -> PaymentResult {
        await withCheckedContinuation { continuation in
            client.start(orderID: orderID) { result in
                switch result {
                case .success:
                    continuation.resume(returning: .success)
                case .failure(let error) where PayPalError.isCheckoutCanceled(error):
                    continuation.resume(returning: .cancelled)
                case .failure:
                    continuation.resume(returning: .failed)
                }
            }
        }
    }

    // Give return URL back to the SDK
    func handleReturnURL(_ url: URL) {
        client.handleReturnURL(url)
    }
}
