//
//  Screens.swift
//  DeepLinkSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import SwiftUI

// MARK: - Home tab

struct HomeView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        List {
            Section("Products") {
                NavigationLink("Running Shoe", value: Screen.product(id: "123"))
                NavigationLink("Walking Shoe", value: Screen.product(id: "456"))
            }
            Section("Categories") {
                NavigationLink("Men", value: Screen.category(slug: "men"))
                NavigationLink("Women", value: Screen.category(slug: "women"))
            }
        }
        .navigationTitle("Home")
        .toolbar {
            Button("Test Links") { router.showTestLinks = true }
        }
    }
}

struct ProductDetailView: View {
    let id: String

    var body: some View {
        // Screen handles "not found", not the router
        if id == "999" {
            ContentUnavailableView("Product not available", systemImage: "shippingbox", description: Text("ID \(id)"))
        } else {
            VStack(spacing: 12) {
                Image(systemName: "shoe.fill").font(.system(size: 80))
                Text("Product \(id)").font(.title.bold())
                Text("$59.99")
            }
            .navigationTitle("Product")
        }
    }
}

struct CategoryView: View {
    let slug: String

    var body: some View {
        List(1...5, id: \.self) { index in
            NavigationLink("\(slug.capitalized) item \(index)", value: Screen.product(id: "\(slug)-\(index)"))
        }
        .navigationTitle(slug.capitalized)
    }
}

// MARK: - Search tab

struct SearchView: View {
    @Environment(AppRouter.self) private var router
    @State private var text = ""

    var body: some View {
        Form {
            TextField("Search products", text: $text)
            Button("Search") {
                router.searchPath.append(.searchResults(query: text))
            }
            .disabled(text.isEmpty)
        }
        .navigationTitle("Search")
    }
}

struct SearchResultsView: View {
    let query: String

    var body: some View {
        List(1...5, id: \.self) { index in
            NavigationLink("\(query) result \(index)", value: Screen.product(id: "s\(index)"))
        }
        .navigationTitle("\"\(query)\"")
    }
}

// MARK: - Cart tab

struct CartView: View {
    var body: some View {
        ContentUnavailableView("Cart is empty", systemImage: "cart")
            .navigationTitle("Cart")
    }
}

// MARK: - Account tab

struct AccountView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        List {
            if router.isLoggedIn {
                NavigationLink("My Orders", value: Screen.orders)
                Button("Log Out", role: .destructive) { router.logout() }
            } else {
                Button("Log In") { router.showLogin = true }
            }
        }
        .navigationTitle("Account")
    }
}

struct OrdersView: View {
    var body: some View {
        List(["A1", "A2", "A3"], id: \.self) { id in
            NavigationLink("Order \(id)", value: Screen.order(id: id))
        }
        .navigationTitle("Orders")
    }
}

struct OrderDetailView: View {
    let id: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "shippingbox.fill").font(.system(size: 60))
            Text("Order \(id)").font(.title.bold())
            Text("Status: Shipped")
        }
        .navigationTitle("Order")
    }
}

// MARK: - Login

struct LoginView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "person.circle.fill").font(.system(size: 70))
                Text("Log in to continue")
                Button("Log In") { router.didLogin() }
                    .buttonStyle(.borderedProminent)
            }
            .toolbar {
                Button("Cancel") { router.cancelLogin() }
            }
        }
    }
}

// MARK: - Test links (simulates taps from outside)

struct TestLinksView: View {
    @Environment(DeepLinkHandler.self) private var handler
    private let links = [
        "shop://product/123",
        "shop://p/456",
        "shop://category/men",
        "shop://cart",
        "shop://order/A1",
        "shop://search?q=shoes",
        "shop://product/999",
        "shop://search",
        "shop://blog/abc",
        "https://www.shop.com/Product/789/?utm_campaign=diwali",
        "https://evil.com/product/1"
    ]

    var body: some View {
        NavigationStack {
            List(links, id: \.self) { link in
                Button(link) {
                    if let url = URL(string: link) {
                        handler.open(url)
                    }
                }
                .font(.footnote.monospaced())
            }
            .navigationTitle("Test Links")
        }
    }
}
