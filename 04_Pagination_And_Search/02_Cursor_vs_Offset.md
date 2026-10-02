# 02 - Cursor vs Offset

## Offset Pagination
`GET /products?limit=20&skip=40` → "skip 40 items, give me 20"

```
Page 1: skip=0    → items 1–20
Page 2: skip=20   → items 21–40
Page 3: skip=40   → items 41–60
```

## Cursor Pagination
`GET /feed?limit=20&after=abc123` → "give me 20 items after this one"

```
Page 1: after=nil     → items + nextCursor "c20"
Page 2: after="c20"   → items + nextCursor "c40"
Page 3: after="c40"   → items + nextCursor nil (end)
```

## The Problem with Offset

```
You loaded items 1–20.
A new item is inserted at the top.
Page 2 (skip=20) now returns the old item 20 again → DUPLICATE.
If an item is deleted instead → one item is SKIPPED.
```

A cursor points to a specific item, so inserts and deletes don't shift it.

## Comparison

| | Offset (limit/skip) | Cursor (after) |
|---|---------------------|----------------|
| Jump to page N | Yes | No |
| Live data (feeds, chat) | Duplicates / skips | Stable |
| Server cost on deep pages | Slow (skip N rows) | Fast (index seek) |
| Simple to build | Yes | Needs stable sort key |
| Good for | Catalogs, search results, admin tables | Feeds, chat, notifications |

## Client Code — Offset

```swift
struct PageRequest {
    let query: String
    let skip: Int
    let limit: Int
}

var hasMore: Bool {
    return items.count < total
}

let next = PageRequest(query: query, skip: items.count, limit: 20)
```

## Client Code — Cursor

```swift
var nextCursor: String?

var hasMore: Bool {
    return nextCursor != nil
}
```

## De-Duplication (Safety Net for Offset)

```swift
var seenIDs: Set<Int> = []

for product in page.products {
    if !seenIDs.contains(product.id) {
        seenIDs.insert(product.id)
        items.append(product)
    }
}
```

## Senior Point
Ask which one the API supports. Choose cursor for live data (feeds, chat) and offset for stable data (catalog, search). Always de-dupe by `id` on the client.

## One-Liner
Offset is simple but shifts on inserts; cursor is stable for live data; de-dupe by id either way.
