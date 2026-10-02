//
//  DeepLink.swift
//  DeepLinkSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation

// What the link means — one model for every source
enum DeepLink: Equatable {
    case home
    case product(id: String)
    case category(slug: String)
    case cart
    case order(id: String)
    case search(query: String)
}

// Tabs in the app
enum AppTab: Hashable {
    case home
    case search
    case cart
    case account
}

// Screens pushed on a NavigationStack
enum Screen: Hashable {
    case product(id: String)
    case category(slug: String)
    case orders
    case order(id: String)
    case searchResults(query: String)
}

// Rules per route
struct RouteConfig {
    let requiresLogin: Bool
    let tab: AppTab
}

extension DeepLink {
    var config: RouteConfig {
        switch self {
        case .home, .product, .category:
            return RouteConfig(requiresLogin: false, tab: .home)
        case .search:
            return RouteConfig(requiresLogin: false, tab: .search)
        case .cart:
            return RouteConfig(requiresLogin: false, tab: .cart)
        case .order:
            return RouteConfig(requiresLogin: true, tab: .account)
        }
    }
}
