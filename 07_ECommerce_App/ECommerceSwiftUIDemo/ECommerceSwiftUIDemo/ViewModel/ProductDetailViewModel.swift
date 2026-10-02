//
//  ProductDetailViewModel.swift
//  ECommerceSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation
import Observation
// MARK: - Product Detail

@Observable
final class ProductDetailViewModel {
    let product: Product
    private(set) var freshPrice: Money?
    private(set) var isLoadingPrice = true
    private(set) var addedMessage: String?
    private let catalog: CatalogRepository
    private let cart: CartRepository
    private let router: AppRouter

    init(product: Product, catalog: CatalogRepository, cart: CartRepository, router: AppRouter) {
        self.product = product
        self.catalog = catalog
        self.cart = cart
        self.router = router
    }

    func loadPrice() {
        // Static content already on screen; price always fresh
        isLoadingPrice = true
        catalog.fetchFreshPrice(product) { [weak self] price in
            self?.freshPrice = price
            self?.isLoadingPrice = false
        }
    }

    func addToCart() {
        cart.add(product)
        addedMessage = "Added to cart"
    }

    func goToCart() {
        router.showCart()
    }
}
