//
//  RootView.swift
//  DeepLinkSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import SwiftUI

struct RootView: View {
    @Bindable var router: AppRouter
    let handler: DeepLinkHandler

    var body: some View {
        if handler.isAppReady {
            tabs
        } else {
            SplashView()
        }
    }

    private var tabs: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack(path: $router.homePath) {
                HomeView()
                    .navigationDestination(for: Screen.self) { destination($0) }
            }
            .tabItem { Label("Home", systemImage: "house") }
            .tag(AppTab.home)

            NavigationStack(path: $router.searchPath) {
                SearchView()
                    .navigationDestination(for: Screen.self) { destination($0) }
            }
            .tabItem { Label("Search", systemImage: "magnifyingglass") }
            .tag(AppTab.search)

            NavigationStack(path: $router.cartPath) {
                CartView()
                    .navigationDestination(for: Screen.self) { destination($0) }
            }
            .tabItem { Label("Cart", systemImage: "cart") }
            .tag(AppTab.cart)

            NavigationStack(path: $router.accountPath) {
                AccountView()
                    .navigationDestination(for: Screen.self) { destination($0) }
            }
            .tabItem { Label("Account", systemImage: "person") }
            .tag(AppTab.account)
        }
        .sheet(isPresented: $router.showLogin, onDismiss: { router.cancelLogin() }) {
            LoginView()
        }
        .sheet(isPresented: $router.showTestLinks) {
            TestLinksView()
        }
    }

    // One place maps Screen → View
    @ViewBuilder
    private func destination(_ screen: Screen) -> some View {
        switch screen {
        case .product(let id):
            ProductDetailView(id: id)
        case .category(let slug):
            CategoryView(slug: slug)
        case .orders:
            OrdersView()
        case .order(let id):
            OrderDetailView(id: id)
        case .searchResults(let query):
            SearchResultsView(query: query)
        }
    }
}

struct SplashView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "bag.fill")
                .font(.system(size: 60))
            Text("Shop")
                .font(.largeTitle.bold())
            ProgressView()
        }
    }
}
