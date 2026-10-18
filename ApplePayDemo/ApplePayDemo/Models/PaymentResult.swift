//
//  PaymentResult.swift
//  ApplePayDemo
//
//  Created by Medikonda Anil kumar on 18/10/26.
//

import Foundation

// Final outcome of a payment
enum PaymentResult {
    case success, failed, cancelled

    // Alert text for each outcome
    var message: String {
        switch self {
        case .success:   return "🎉 Payment successful!"
        case .failed:    return "❌ Payment failed. Try again."
        case .cancelled: return "Payment cancelled."
        }
    }
}
