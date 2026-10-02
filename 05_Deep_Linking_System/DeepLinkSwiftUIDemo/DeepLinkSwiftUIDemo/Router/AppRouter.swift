//
//  AppRouter.swift
//  DeepLinkSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import UIKit
import Observation

@Observable
final class AppRouter {
    var selectedTab: AppTab = .home
    var homePath: [Screen] = []
    var searchPath: [Screen] = []
    var cartPath: [Screen] = []
    var accountPath: [Screen] = []
    var showLogin = false
    var showTestLinks = false
    var isLoggedIn = false
    private var pendingAfterLogin: DeepLink?

    // MARK: - Handle a parsed link

    func handle(_ link: DeepLink) {
        print("ROUTER: handle \(link)")
        // 1. Dismiss anything presented
        showTestLinks = false
        // 2. Auth rule
        if link.config.requiresLogin && !isLoggedIn {
            print("ROUTER: login required, saving \(link)")
            pendingAfterLogin = link
            showLogin = true
            return
        }
        // 3. Switch tab + build a fresh stack
        selectedTab = link.config.tab
        switch link {
        case .home:
            homePath = []
        case .product(let id):
            homePath = [.product(id: id)]
        case .category(let slug):
            homePath = [.category(slug: slug)]
        case .cart:
            cartPath = []
        case .order(let id):
            accountPath = [.orders, .order(id: id)]
        case .search(let query):
            searchPath = [.searchResults(query: query)]
        }
    }

    // MARK: - Unknown link fallback

    func handleUnknown(_ url: URL) {
        print("ROUTER: unknown \(url.absoluteString)")
        // Our website → let Safari show it
        if url.scheme == "https", let host = url.host, host.hasSuffix("shop.com") {
            UIApplication.shared.open(url)
            return
        }
        handle(.home)
    }

    // MARK: - Login

    func didLogin() {
        isLoggedIn = true
        showLogin = false
        print("ROUTER: logged in")
        if let link = pendingAfterLogin {
            pendingAfterLogin = nil
            handle(link)
        }
    }

    func cancelLogin() {
        showLogin = false
        pendingAfterLogin = nil
    }

    func logout() {
        isLoggedIn = false
        accountPath = []
    }
}
