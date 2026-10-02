//
//  CartRepository.swift
//  ECommerceSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation

final class CartRepository {
    private(set) var items: [CartItem] = []
    private(set) var totals: CartTotals?
    private(set) var isPricing = false
    private(set) var pricingError: String?
    var onChange: (() -> Void)?

    private let server: FakeCommerceServer
    private let maxPerItem = 10
    private var pricingGeneration = 0
    private let fileURL = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("cart.json")

    init(server: FakeCommerceServer) {
        self.server = server
        load()
    }

    var count: Int {
        var total = 0
        for item in items {
            total += item.quantity
        }
        return total
    }

    // MARK: - Local-first writes (instant, then reprice)

    func add(_ product: Product) {
        if let index = items.firstIndex(where: { $0.id == product.id }) {
            items[index].quantity = min(items[index].quantity + 1, maxPerItem)
        } else {
            items.append(CartItem(id: product.id, title: product.title, quantity: 1))
        }
        print("CART: add \(product.title)")
        commit()
    }

    func setQuantity(_ id: Int, to quantity: Int) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        if quantity <= 0 {
            items.remove(at: index)
        } else {
            items[index].quantity = min(quantity, maxPerItem)
        }
        commit()
    }

    func clear() {
        items = []
        totals = nil
        save()
        onChange?()
    }

    // MARK: - Server pricing (truth for money)

    func refreshTotals() {
        guard !items.isEmpty else {
            totals = nil
            onChange?()
            return
        }
        pricingGeneration += 1
        let generation = pricingGeneration
        isPricing = true
        pricingError = nil
        onChange?()
        server.priceCart(items) { [weak self] result in
            // Older response after a newer change → ignore
            guard let self = self, generation == self.pricingGeneration else { return }
            self.isPricing = false
            switch result {
            case .success(let totals):
                self.totals = totals
                print("CART: priced → \(totals.total.formatted)")
            case .failure:
                self.pricingError = "Couldn't update prices"
            }
            self.onChange?()
        }
    }

    func applyServerTotals(_ totals: CartTotals) {
        self.totals = totals
        onChange?()
    }

    // MARK: - Persistence (survives app kill)

    private func commit() {
        save()
        onChange?()
        refreshTotals()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let saved = try? JSONDecoder().decode([CartItem].self, from: data) else { return }
        items = saved
        print("CART: restored \(saved.count) items")
    }
}
