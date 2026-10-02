//
//  RootView.swift
//  ECommerceSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import SwiftUI

struct RootView: View {
    let deps: AppDependencies
    @Bindable var router: AppRouter
    @State private var catalogVM: CatalogViewModel
    @State private var cartVM: CartViewModel
    @State private var checkoutVM: CheckoutViewModel
    @State private var ordersVM: OrdersViewModel

    init(deps: AppDependencies) {
        self.deps = deps
        self.router = deps.router
        _catalogVM = State(initialValue: CatalogViewModel(catalog: deps.catalog))
        _cartVM = State(initialValue: CartViewModel(cart: deps.cart, router: deps.router))
        _checkoutVM = State(initialValue: CheckoutViewModel(cart: deps.cart, server: deps.server, router: deps.router))
        _ordersVM = State(initialValue: OrdersViewModel(server: deps.server))
    }

    var body: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack(path: $router.shopPath) {
                CatalogView(viewModel: catalogVM, router: router)
                    .navigationDestination(for: ShopScreen.self) { screen in
                        switch screen {
                        case .product(let product):
                            ProductDetailView(product: product, deps: deps)
                        }
                    }
            }
            .tabItem { Label("Shop", systemImage: "bag") }
            .tag(AppTab.shop)

            NavigationStack(path: $router.cartPath) {
                CartView(viewModel: cartVM)
                    .navigationDestination(for: CartScreen.self) { _ in
                        CheckoutView(viewModel: checkoutVM)
                    }
            }
            .tabItem { Label("Cart", systemImage: "cart") }
            .badge(cartVM.count)
            .tag(AppTab.cart)

            NavigationStack {
                OrdersView(viewModel: ordersVM)
            }
            .tabItem { Label("Orders", systemImage: "shippingbox") }
            .tag(AppTab.orders)
        }
    }
}
