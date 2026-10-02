# 01 - Requirements

## Big Picture

```
┌────────────────────────── App ──────────────────────────┐
│  Home   Catalog   Search   PDP   Cart   Checkout  Orders │  ← Feature modules (MVVM-C)
├──────────────────────────────────────────────────────────┤
│  Networking · ImageLoader · Storage · Auth · DeepLink    │  ← Core modules (systems 01–06)
│  Analytics · RemoteConfig · DesignSystem                 │
└──────────────────────────────────────────────────────────┘
                              │
                 API Gateway → Catalog · Cart · Order · Payment services
```

**Rule:** reuse systems 01–06 as core modules; features only combine them.

## Functional
- Browse home feed, categories and product lists (paginated)
- Search with filters and sort
- Product detail: images, variants (size/color), price, stock
- Cart: add, update quantity, remove; works as guest and logged in
- Checkout: address → delivery → payment → place order
- Orders: list, detail, tracking
- Deep links and push open products, cart and orders
- Wishlist (optional)

## Non-Functional
- Fast launch (< 2s to usable home), smooth 60fps scrolling
- Browse works offline with cached data
- Cart never lost (app kill, logout/login, device change)
- **Prices and stock always confirmed by the server** before payment
- Placing an order is idempotent: double tap never charges twice
- Handles sale-day traffic spikes gracefully
- Analytics for every key step (view, add to cart, checkout, purchase)

## Out of Scope
- Seller app, admin panel
- Building the payment gateway itself (use a PSP SDK / Apple Pay)

## Clarifying Questions to Ask
- Scale: users, products, peak traffic (flash sales)?
- Guest checkout allowed?
- Payment methods: cards, Apple Pay, UPI, COD?
- Multiple countries / currencies / languages?
- How dynamic is the home screen: server-driven?

## Core Models

```swift
struct Product: Codable, Identifiable {
    let id: String
    let title: String
    let images: [URL]
    let variants: [Variant]
}

struct Variant: Codable, Identifiable {
    let id: String              // SKU
    let size: String
    let color: String
    let price: Money
    let inStock: Bool
}

struct Money: Codable {
    let amount: Int             // minor units: cents / paise, never Double
    let currency: String        // "USD", "INR"
}

struct CartItem: Codable, Identifiable {
    let id: String              // variant id
    var quantity: Int
}

struct Cart: Codable {
    var items: [CartItem]
    var subtotal: Money         // calculated by the server
    var total: Money
}

enum OrderStatus: String, Codable {
    case placed
    case paid
    case shipped
    case delivered
    case cancelled
}
```

## One-Liner
An e-commerce app is systems 01–06 combined: features on top, shared core below, and the server as the source of truth for price, stock and orders.
