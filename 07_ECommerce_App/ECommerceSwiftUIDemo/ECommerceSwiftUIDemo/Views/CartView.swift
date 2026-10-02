//
//  CartView.swift
//  ECommerceSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import SwiftUI

// MARK: - Cart

struct CartView: View {
    let viewModel: CartViewModel

    var body: some View {
        List {
            if viewModel.items.isEmpty {
                ContentUnavailableView("Cart is empty", systemImage: "cart")
            }
            ForEach(viewModel.items) { item in
                HStack {
                    VStack(alignment: .leading) {
                        Text(item.title).font(.headline)
                        if let price = viewModel.unitPrice(item) {
                            Text(price.formatted).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Button("−") { viewModel.decrement(item) }.buttonStyle(.bordered)
                    Text("\(item.quantity)").frame(width: 28)
                    Button("+") { viewModel.increment(item) }.buttonStyle(.bordered)
                }
            }
            if !viewModel.items.isEmpty {
                Section {
                    if viewModel.isPricing {
                        HStack { ProgressView(); Text("Updating prices…") }
                    } else if let totals = viewModel.totals {
                        totalRow("Subtotal", totals.subtotal)
                        totalRow("Delivery", totals.delivery)
                        totalRow("Total", totals.total).bold()
                    }
                    if let error = viewModel.errorMessage {
                        Text(error).foregroundStyle(.red)
                    }
                    Button("Checkout") { viewModel.checkout() }
                        .disabled(!viewModel.canCheckout)
                }
            }
        }
        .navigationTitle("Cart")
    }

    private func totalRow(_ title: String, _ money: Money) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(money.formatted)
        }
    }
}

// MARK: - Checkout

struct CheckoutView: View {
    @Bindable var viewModel: CheckoutViewModel

    var body: some View {
        Form {
            switch viewModel.step {
            case .address:
                Section("Delivery Address") {
                    TextField("Name", text: $viewModel.name)
                    TextField("Street", text: $viewModel.street)
                    TextField("City", text: $viewModel.city)
                }
                Button("Continue") { viewModel.continueToReview() }
                    .disabled(!viewModel.canContinue)
            case .review:
                reviewSection
                Button("Place Order") { viewModel.placeOrder() }
                    .buttonStyle(.borderedProminent)
                debugSection
            case .placing:
                HStack { ProgressView(); Text("Placing order…") }
            case .priceChanged(let message):
                Label(message, systemImage: "exclamationmark.triangle").foregroundStyle(.orange)
                Button("Review New Total") { viewModel.confirmNewPrice() }
            case .success(let orderID):
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill").font(.system(size: 60)).foregroundStyle(.green)
                    Text("Order \(orderID) placed").font(.headline)
                    Button("View Orders") { viewModel.finish() }
                }
                .frame(maxWidth: .infinity)
            case .failed(let message):
                Text(message).foregroundStyle(.red)
                Button("Retry") { viewModel.retry() }
                debugSection
            }
        }
        .navigationTitle("Checkout")
        .navigationBarBackButtonHidden(viewModel.step == .placing)
    }

    private var reviewSection: some View {
        Section("Review") {
            Text("\(viewModel.name), \(viewModel.street), \(viewModel.city)")
            ForEach(viewModel.items) { item in
                Text("\(item.quantity) × \(item.title)")
            }
            if let total = viewModel.expectedTotal {
                HStack { Text("Total").bold(); Spacer(); Text(total.formatted).bold() }
            }
        }
    }

    private var debugSection: some View {
        Section("Debug") {
            Button("Raise prices 10%") { viewModel.debugRaisePrices() }
            Button("Lose next order response") { viewModel.debugFailNextWithTimeout() }
            Button("Toggle offline") { viewModel.debugToggleOffline() }
        }
    }
}

// MARK: - Orders

struct OrdersView: View {
    let viewModel: OrdersViewModel

    var body: some View {
        List(viewModel.orders) { order in
            VStack(alignment: .leading, spacing: 4) {
                Text(order.id).font(.headline)
                Text("\(order.items.count) items · \(order.total.formatted)").foregroundStyle(.secondary)
            }
        }
        .overlay {
            if viewModel.orders.isEmpty {
                ContentUnavailableView("No orders yet", systemImage: "shippingbox")
            }
        }
        .navigationTitle("Orders")
        .onAppear { viewModel.load() }
    }
}
