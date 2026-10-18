//
//  CheckoutView.swift
//  ApplePayDemo
//
//  Created by Medikonda Anil kumar on 18/10/26.
//

import SwiftUI
import PassKit

// Checkout UI – only displays ViewModel state
struct CheckoutView: View {
    @StateObject private var viewModel = CheckoutViewModel()

    var body: some View {
        NavigationStack {
            List {
                menuSection
                cartSection
            }
            .navigationTitle("Demo Cafe")
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
        }
    }

    // Product list with Add buttons
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

    // Official Apple Pay button, or message if unavailable
    @ViewBuilder
    private var payButton: some View {
        if viewModel.canPay {
            PayWithApplePayButton(.buy) { viewModel.payTapped() }
                .frame(height: 50)
                .disabled(viewModel.isCartEmpty || viewModel.isPaying)
        } else {
            Text("Apple Pay not available").foregroundStyle(.secondary)
        }
    }
}

#Preview { CheckoutView() }
