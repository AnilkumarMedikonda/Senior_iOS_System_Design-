# 04 - Catalog Caching

## Rule
Cache by **how often data changes** and **how bad stale data is**.

| Data | Changes | Cache | TTL | Stale OK? |
|------|---------|-------|-----|-----------|
| Categories, menus | Rarely | Disk | 24 h | Yes |
| Home feed layout | Daily / campaigns | Disk + stale-while-revalidate | 10 min | Yes |
| Product list / search pages | Often | Memory | 5 min | Yes (prices re-checked later) |
| Product detail (title, images) | Rarely | Memory + disk | 30 min | Yes |
| **Price, stock** | Constantly | **No / very short** | 0–30 s | **No** |
| Images | Never (per URL) | Memory + disk (02) | 7 days | Yes |
| Cart, orders | User actions | Local DB + sync (03) | — | Synced |

## Stale-While-Revalidate (home, lists)

```
Open Home
   → show cached feed instantly
   → fetch fresh in background
   → fresh differs? → update UI quietly
```

Fast launch even on slow networks; works offline.

## Split Static vs Dynamic Data

```
GET /products/123          → title, images, description   (cache 30 min)
GET /products/123/offer    → price, stock, delivery date  (always fresh)
```

PDP shows cached content immediately, then fills price and stock from the fresh call.

## HTTP Caching
- Server sends `Cache-Control: max-age=600` and `ETag`
- `URLCache` stores responses; next request sends `If-None-Match`
- `304 Not Modified` → no body downloaded, cached copy reused

```swift
let cache = URLCache(memoryCapacity: 20 * 1024 * 1024, diskCapacity: 100 * 1024 * 1024)
let config = URLSessionConfiguration.default
config.urlCache = cache
config.requestCachePolicy = .useProtocolCachePolicy
```

## Invalidation Triggers

| Trigger | Action |
|---------|--------|
| TTL expired | Refetch on next view |
| Pull to refresh | Bypass cache |
| Add to cart / checkout | Re-fetch price + stock for those items |
| Logout | Clear user-specific caches (cart, orders, recommendations) |
| App version / config change | Clear layout caches |
| Sale starts (remote config flag) | Clear price caches |

## Senior Point
Never show a cached price at the moment of commitment. Cached prices are fine for browsing, but cart and checkout always use fresh server prices. Splitting static content from price/stock lets you cache aggressively without risk.

## One-Liner
Cache static catalog data long, show cached feeds instantly while revalidating, and always fetch price and stock fresh before the user commits.
