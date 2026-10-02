# 05 - Scale and Tradeoffs

## Performance

| Area | Technique |
|------|-----------|
| Launch | Minimal work in `didFinishLaunching`, lazy services, cached home feed |
| Lists | Lazy stacks, pagination (04), cell prefetch, downsampled images (02) |
| Images | CDN with size params (`?w=300`), WebP/AVIF, memory + disk cache |
| Network | HTTP/2, gzip, `select` fields, batch calls on Home |
| App size | Asset catalogs, on-demand resources, strip unused SDKs |

## Sale-Day Traffic (flash sales)

```
Millions open the app at 12:00
   → server overloaded → 503 / 429
```

- Exponential backoff **with jitter** → clients don't retry at the same second
- Respect `Retry-After` headers
- Cache everything non-critical (home, categories) → fewer calls
- Remote config can **switch off** heavy features (recommendations) during the sale
- Queue / waiting-room screen for checkout if the server asks

## Release Safety

| Tool | Why |
|------|-----|
| Feature flags (remote config) | Turn features on/off without an App Store release |
| Server-driven UI (home) | Change layouts and campaigns instantly |
| Phased rollout | 1% → 10% → 100%, stop on crash spikes |
| Force / soft update | Block very old versions with broken APIs |
| Crash + performance monitoring | Catch problems in minutes |

## Analytics Funnel

```
view_home → view_product → add_to_cart → begin_checkout → add_payment → purchase
```

Track every step with product ID, price and source (deep link, search, push), and batch events (send every 30s or in background) to save battery.

## Key Tradeoffs

| Decision | Option A | Option B | Usually |
|----------|----------|----------|---------|
| UI framework | SwiftUI (fast to build) | UIKit (mature, control) | SwiftUI new screens, UIKit legacy |
| Home screen | Native screens | Server-driven UI | Server-driven for campaigns |
| Checkout | Native | Web view | Native for conversion, web if many payment rules |
| Cart | Server only | Local-first + sync | Local-first, server totals |
| Modules | One target | Swift Packages per feature | Packages once team > ~5 devs |
| Caching | Aggressive (fast, maybe stale) | Minimal (fresh, slower) | Aggressive for content, fresh for price |
| Pagination | Offset | Cursor | Offset catalog, cursor feeds |

## Localization and Money
- `Money` in minor units + currency code; format with `NumberFormatter` (currency style, user locale)
- Server decides prices per region; the app never converts currency
- RTL layouts, Dynamic Type, VoiceOver labels on prices and buttons

## Interview Answer Structure (45 min)

```
1. Requirements + scale questions        (5 min)
2. High-level modules diagram            (5 min)
3. Deep dive: Cart + Checkout            (15 min)
4. Deep dive: Catalog caching + images   (10 min)
5. Scale, failures, tradeoffs            (10 min)
```

## Senior Point
Name the trade-off before the choice: "I'd cache the catalog aggressively because browsing must be fast, but always fetch price fresh at checkout because correctness matters more there." Interviewers grade the reasoning, not the pick.

## One-Liner
Fast where it's browsing, correct where it's money, safe where it's releases, and gentle on the server when traffic spikes.
