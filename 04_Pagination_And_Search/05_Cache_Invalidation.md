# 05 - Cache Invalidation

## Idea
Cache pages so going back or re-searching is instant, but don't show data that's too old.

```
Key:   "query|skip"      e.g. "phone|0", "phone|20", "|0" (no query)
Value: ProductPage + savedAt
```

## Code

```swift
final class PageCache {
    private var storage: [String: (page: ProductPage, savedAt: Date)] = [:]
    private let ttl: TimeInterval = 5 * 60

    func page(query: String, skip: Int) -> ProductPage? {
        let key = "\(query)|\(skip)"
        guard let entry = storage[key] else { return nil }
        if Date().timeIntervalSince(entry.savedAt) > ttl {
            storage[key] = nil
            return nil
        }
        return entry.page
    }

    func save(_ page: ProductPage, query: String, skip: Int) {
        storage["\(query)|\(skip)"] = (page, Date())
    }

    func removeAll() {
        storage.removeAll()
    }
}
```

## When to Invalidate

| Trigger | Action |
|---------|--------|
| TTL expired (5 min) | Drop that page, fetch fresh |
| Pull to refresh | Clear cache, reload from page 1 |
| User edits/creates data | Clear the affected list |
| Logout | Clear everything |
| Memory warning | Clear everything |

## Strategies

| Strategy | How | Good For |
|----------|-----|----------|
| TTL | Expire after N minutes | Catalogs, search |
| Refresh on demand | Pull to refresh | Any list |
| Stale-while-revalidate | Show cache now, fetch fresh in background | Feeds, home screen |
| Event-based | Clear on create/update/delete | User-owned lists |

## Full Flow

```
User types "phone" → debounce 400ms → cancel old → query = "phone"
   │
   ├─ cache "phone|0" fresh?  → yes → show instantly
   │                          → no  → GET /products/search?q=phone&limit=20&skip=0
   │                                  → save cache → show
   ▼
Scroll near end (threshold 5) → !isLoading && hasMore
   │
   └─ cache "phone|20" or GET ...&skip=20 → de-dupe by id → append
   ▼
Pull to refresh → clear cache → reload page 1
```

## Senior Point
Page-based caching breaks if the data shifts between pages. When refreshing, **reset the whole list from page 1**; never mix fresh pages with old cached pages.

## One-Liner
Cache by query + page with a TTL, and on refresh clear everything and start again from page 1.
