# 03 - Route Registry

## Idea
The parser answers **"what"** (`.product("123")`). The router answers **"how to show it"**. A registry maps each route to a handler, so adding a route doesn't touch existing code (OCP).

```
DeepLink ──► Router ──► rules (auth?) ──► handler ──► navigation stack
```

## Route Config

```swift
struct RouteConfig {
    let requiresLogin: Bool
    let tab: AppTab
}

enum AppTab {
    case home
    case search
    case cart
    case account
}

extension DeepLink {
    var config: RouteConfig {
        switch self {
        case .home:
            return RouteConfig(requiresLogin: false, tab: .home)
        case .product, .category:
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
```

## Router (SwiftUI)

```swift
enum Screen: Hashable {
    case product(id: String)
    case category(slug: String)
    case order(id: String)
    case searchResults(query: String)
}

@Observable
final class AppRouter {
    var selectedTab: AppTab = .home
    var path = NavigationPath()
    var showLogin = false
    var isLoggedIn = false
    private var pendingAfterLogin: DeepLink?

    func handle(_ link: DeepLink) {
        // 1. Auth rule
        if link.config.requiresLogin && !isLoggedIn {
            pendingAfterLogin = link
            showLogin = true
            return
        }
        // 2. Reset stack, switch tab
        path = NavigationPath()
        selectedTab = link.config.tab
        // 3. Push target
        switch link {
        case .home, .cart:
            break
        case .product(let id):
            path.append(Screen.product(id: id))
        case .category(let slug):
            path.append(Screen.category(slug: slug))
        case .order(let id):
            path.append(Screen.order(id: id))
        case .search(let query):
            path.append(Screen.searchResults(query: query))
        }
    }

    func didLogin() {
        isLoggedIn = true
        showLogin = false
        if let link = pendingAfterLogin {
            pendingAfterLogin = nil
            handle(link)
        }
    }
}
```

## UIKit Version
The same idea with a Coordinator: `AppCoordinator.handle(link)` → selects the tab → `popToRootViewController` → pushes the target VC.

## Stack Building
A deep link should feel like the user navigated there:

```
.product("123")  → Home tab → [ProductDetail]          (Back → Home)
.order("A1")     → Account tab → [Orders, OrderDetail] (Back → Orders)
```

## Senior Point
Keep the router the **only** place that changes navigation. Push notifications, Universal Links, in-app banners and QR codes all call `router.handle(link)`, so there's one code path to test.

## One-Liner
Parser says what, router decides how: check auth, switch tab, reset the stack, push the target.
