//
//  ApplePayService.swift
//  ApplePayDemo
//
//  Created by Medikonda Anil kumar on 18/10/26.
//

import Foundation
import PassKit

// Apple Pay contract – lets ViewModel be tested with a fake
protocol ApplePayServiceProtocol {
    var canPay: Bool { get }
    func pay(items: [Product], total: Decimal, completion: @escaping (PaymentResult) -> Void)
}

// Real Apple Pay using PassKit
final class ApplePayService: NSObject, ApplePayServiceProtocol {

    private let merchantID = "merchant.com.yourname.applepaydemo"   // must match capability
    private let networks: [PKPaymentNetwork] = [.visa, .masterCard, .amex]
    private let api: PaymentAPIProtocol

    private var controller: PKPaymentAuthorizationController?   // keep sheet alive
    private var result: PaymentResult = .cancelled              // default = user cancelled
    private var total: Decimal = 0
    private var completion: ((PaymentResult) -> Void)?

    init(api: PaymentAPIProtocol = MockPaymentAPI()) {
        self.api = api
    }

    // Device supports Apple Pay + has a card?
    var canPay: Bool {
        PKPaymentAuthorizationController.canMakePayments(usingNetworks: networks)
    }

    // Build request and show the Apple Pay sheet
    func pay(items: [Product], total: Decimal, completion: @escaping (PaymentResult) -> Void) {
        self.completion = completion
        self.total = total
        self.result = .cancelled

        var summary = items.map {
            PKPaymentSummaryItem(label: $0.name, amount: NSDecimalNumber(decimal: $0.price))
        }
        summary.append(PKPaymentSummaryItem(label: "Demo Cafe",              // last = total
                                            amount: NSDecimalNumber(decimal: total)))

        let request = PKPaymentRequest()
        request.merchantIdentifier   = merchantID
        request.countryCode          = "US"
        request.currencyCode         = "USD"
        request.supportedNetworks    = networks
        request.merchantCapabilities = .threeDSecure
        request.paymentSummaryItems  = summary

        controller = PKPaymentAuthorizationController(paymentRequest: request)
        controller?.delegate = self
        controller?.present { presented in
            if !presented { completion(.failed) }   // wrong Merchant ID / capability
        }
    }
}

// MARK: - Delegate
extension ApplePayService: PKPaymentAuthorizationControllerDelegate {

    // Face ID passed → send token to server → tell sheet result
    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController,
                                        didAuthorizePayment payment: PKPayment,
                                        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        api.charge(token: payment.token.paymentData, amount: total) { success in
            self.result = success ? .success : .failed
            completion(PKPaymentAuthorizationResult(status: success ? .success : .failure, errors: nil))
        }
    }

    // Always called last → dismiss sheet and return result
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss {
            DispatchQueue.main.async {
                self.completion?(self.result)
                self.completion = nil
                self.controller = nil
            }
        }
    }
}
