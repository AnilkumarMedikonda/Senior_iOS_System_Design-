# 02 - Module Breakdown

## Layers

```
App target            AppCoordinator, DI container, launch
   │
Feature modules       Home · Catalog · Search · PDP · Cart · Checkout · Orders · Account
   │  (each: Views + ViewModels + Coordinator)
Domain                Use cases: AddToCart, PlaceOrder, ApplyCoupon
   │
Core modules          Networking (01) · ImageLoader (02) · Storage/Sync (03)
                      Pagination (04) · DeepLink (05) · Auth (06)
                      Analytics · RemoteConfig · DesignSystem
```

## Dependency Rules
- Features depend on **Core** and **Domain**, never on other features
- Core modules depend on nothing feature-specific
- Feature → Feature communication goes through the **Coordinator / Router**
- Each module is a **Swift Package** → faster builds, clear boundaries, parallel teams

```
PDP ──✗──► Cart          (no direct import)
PDP ──► Router.show(.cart) ──► Cart   ✅
```

## Feature Map

| Module | Main Screens | Uses Core |
|--------|--------------|-----------|
| Home | Server-driven feed, banners | Networking, ImageLoader, RemoteConfig |
| Catalog | Category list, product grid | Pagination, ImageLoader |
| Search | Search bar, filters, results | Pagination (debounce, cancel) |
| PDP | Gallery, variants, add to cart | ImageLoader, Analytics |
| Cart | Items, quantity, totals | Storage/Sync, Auth |
| Checkout | Address, delivery, payment, review | Networking, Auth, Payment SDK |
| Orders | List, detail, tracking | Pagination, Auth, DeepLink |
| Account | Profile, addresses, logout | Auth |

## Architecture per Feature — MVVM-C

```
Coordinator ──creates──► View ◄──state── ViewModel ──► UseCase ──► Repository ──► Core
     ▲                                       │
     └──────── navigation events ────────────┘
```

## Shared Services (DI)

```swift
struct AppDependencies {
    let apiClient: APIClient            // 01 + auth interceptor (06)
    let imageLoader: ImageLoader        // 02
    let cartRepository: CartRepository  // 03 offline sync
    let router: AppRouter               // 05
    let session: SessionManager         // 06
    let analytics: Analytics
    let remoteConfig: RemoteConfig
}
```

Created once in the App target and passed down by coordinators: no singletons inside features → easy to test with mocks.

## Team Ownership

```
Team Discovery  → Home, Catalog, Search
Team Product    → PDP
Team Purchase   → Cart, Checkout, Orders
Team Platform   → Core modules, DesignSystem, CI
```

## Senior Point
Modules follow **teams and change frequency**, not screens. Features never import each other; the Router connects them. This keeps build times low and lets teams ship independently.

## One-Liner
Feature modules on top, shared core modules below, coordinators connect features, and dependencies are injected, never imported sideways.
