//
//  ApplePayDemoApp.swift
//  ApplePayDemo
//
//  Created by Medikonda Anil kumar on 18/10/26.
//

import SwiftUI

// App entry point – opens the checkout screen
@main
struct ApplePayDemoApp: App {
    var body: some Scene {
        WindowGroup { CheckoutView() }
    }
}
