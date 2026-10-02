# 01 - Requirements

## Big Picture

```
Universal Link   https://shop.com/product/123   ┐
Custom Scheme    shop://product/123             ├─► DeepLinkParser ─► DeepLink enum ─► Router ─► Screen
Push Payload     { "link": "/product/123" }     ┘        (normalize)      (one model)    (navigate)
```

**Rule:** every entry point is converted into **one `DeepLink` enum** first. Navigation code never reads raw URLs.

## Functional
- Open the right screen from Universal Links, custom schemes and push notifications
- Support: Home, Product Detail, Category, Cart, Order Detail, Search
- Work when the app is killed (cold start) and in the background (warm start)
- Routes that need login → show login → then continue to the target screen
- Unknown or invalid links → safe fallback, never a crash

## Non-Functional
- One parser and one router for all sources
- Easy to add a new route (one line)
- Deep link must not be lost if it arrives before the UI is ready
- Analytics: track source and campaign (`utm_*`)
- Testable without launching the app

## Out of Scope
- Deferred deep links (install → open), handled by a third-party SDK
- Web fallback pages

## Clarifying Questions to Ask
- Which sources: Universal Links, custom scheme, push, QR codes?
- Which screens need login?
- Should old link formats keep working (`/p/123` vs `/product/123`)?
- What happens on an unknown link: Home, Safari, or an error?

## Models

```swift
enum DeepLink: Equatable {
    case home
    case product(id: String)
    case category(slug: String)
    case cart
    case order(id: String)
    case search(query: String)
}

enum DeepLinkSource {
    case universalLink
    case customScheme
    case push
}

struct DeepLinkRequest {
    let link: DeepLink
    let source: DeepLinkSource
    let campaign: String?
}
```

## One-Liner
Every entry point becomes one DeepLink enum, one router navigates, and nothing is lost on cold start.
