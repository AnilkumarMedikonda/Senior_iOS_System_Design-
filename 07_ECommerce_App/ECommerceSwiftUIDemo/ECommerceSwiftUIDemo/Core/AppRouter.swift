//
//  AppRouter.swift
//  ECommerceSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation
import Observation

// MARK: - Navigation

enum AppTab: Hashable {
    case shop
    case cart
    case orders
}

enum ShopScreen: Hashable {
    case product(Product)
}

enum CartScreen: Hashable {
    case checkout
}

@Observable
final class AppRouter {
    var selectedTab: AppTab = .shop
    var shopPath: [ShopScreen] = []
    var cartPath: [CartScreen] = []

    func showProduct(_ product: Product) {
        selectedTab = .shop
        shopPath.append(.product(product))
    }

    func showCart() {
        selectedTab = .cart
        cartPath = []
    }

    func showCheckout() {
        selectedTab = .cart
        cartPath = [.checkout]
    }

    func showOrders() {
        cartPath = []
        selectedTab = .orders
    }
}

// MARK: - Dependencies (created once, injected everywhere)

final class AppDependencies {
    let client: APIClient
    let server: FakeCommerceServer
    let catalog: CatalogRepository
    let cart: CartRepository
    let router: AppRouter

    init() {
        let client = APIClient()
        let server = FakeCommerceServer()
        self.client = client
        self.server = server
        self.catalog = CatalogRepository(client: client, server: server)
        self.cart = CartRepository(server: server)
        self.router = AppRouter()
    }
}
