//
//  PaymentAPI.swift
//  ApplePayDemo
//
//  Created by Medikonda Anil kumar on 18/10/26.
//

import Foundation

// Backend contract – swap mock for real server later
protocol PaymentAPIProtocol {
    func charge(token: Data, amount: Decimal, completion: @escaping (Bool) -> Void)
}

// Fake server for the demo
final class MockPaymentAPI: PaymentAPIProtocol {
    var shouldSucceed = true   // false = test failure

    // Simulates network call to charge the token
    func charge(token: Data, amount: Decimal, completion: @escaping (Bool) -> Void) {
        print("➡️ Charging $\(amount)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            completion(self.shouldSucceed)
        }
    }
}
