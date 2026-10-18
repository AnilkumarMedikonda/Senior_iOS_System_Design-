//
//  CheckoutView.swift
//  PayPalDemo
//
//  Created by Medikonda Anil kumar on 18/10/26.
//

import SwiftUI
import PaymentButtons

// Checkout UI – displays ViewModel state
struct CheckoutView: View {
    @StateObject private var viewModel = CheckoutViewModel()

    var body: some View {
        NavigationStack {
            List {
                menuSection
                cartSection
            }
            .navigationTitle("PayPal Cafe")
            .toolbar {
                Button("Clear") { viewModel.clearCart() }
                    .disabled(viewModel.isCartEmpty)
            }
            .safeAreaInset(edge: .bottom) { payButton.padding() }
            .alert(viewModel.alertMessage ?? "",
                   isPresented: Binding(
                       get: { viewModel.alertMessage != nil },
                       set: { if !$0 { viewModel.alertMessage = nil } })) {
                Button("OK", role: .cancel) { }
            }
            // Return from PayPal (custom scheme)
            .onOpenURL { viewModel.handleReturnURL($0) }
            // Return from PayPal (Universal Link)
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                if let url = activity.webpageURL { viewModel.handleReturnURL(url) }
            }
        }
    }

    // Products with Add buttons
    private var menuSection: some View {
        Section("Menu") {
            ForEach(viewModel.products) { product in
                HStack {
                    Text("\(product.emoji) \(product.name)")
                    Spacer()
                    Text(product.price, format: .currency(code: "USD"))
                        .foregroundStyle(.secondary)
                    Button("Add") { viewModel.add(product) }
                        .buttonStyle(.bordered)
                }
            }
        }
    }

    // Cart count + total
    private var cartSection: some View {
        Section("Cart (\(viewModel.cart.count) items)") {
            HStack {
                Text("Total").bold()
                Spacer()
                Text(viewModel.total, format: .currency(code: "USD")).bold()
            }
        }
    }

    // Official PayPal button + loader
    private var payButton: some View {
        VStack(spacing: 10) {
            PayPalButton.Representable(color: .gold, size: .collapsed) {
                viewModel.payPalTapped()
            }
            .frame(height: 50)

            if viewModel.isPaying { ProgressView() }
        }
        .disabled(viewModel.isCartEmpty || viewModel.isPaying)
    }
}

#Preview { CheckoutView() }
