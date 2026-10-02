# 01 - Requirements

## Big Picture

```
View (List + Search bar)
   │  last rows appear / user types
   ▼
ViewModel ── debounce 400ms ── cancel old request
   │
   ▼
Repository ── page cache (query + page) ── TTL
   │
   ▼
APIClient → GET /products?limit=20&skip=40
          → GET /products/search?q=phone&limit=20&skip=0
```

**Rule:** load small pages on demand, never block scrolling, and never show results from an old query.

## Functional
- Show a product list that loads 20 items per page
- Load the next page automatically near the end of the list
- Search products by text, with paginated results
- Pull to refresh reloads from page 1
- Show loading, empty, error and "end of list" states

## Non-Functional
- Smooth scrolling, no duplicate items
- No request per keystroke (debounce)
- Old search requests cancelled when the user keeps typing
- Results from an old query must never replace newer ones
- Cache pages for fast back-navigation, with expiry

## Out of Scope
- Offline search
- Search suggestions and autocomplete
- Filters and sorting

## Clarifying Questions to Ask
- Does the API support cursor or only offset (limit/skip)?
- How often does the data change? Can items be inserted while scrolling?
- Is search server-side or local?
- Page size? Total count available?

## Models

```swift
struct Product: Decodable, Identifiable {
    let id: Int
    let title: String
    let price: Double
}

struct ProductPage: Decodable {
    let products: [Product]
    let total: Int
    let skip: Int
    let limit: Int
}

enum ListState {
    case idle
    case loading            // first page
    case loadingMore        // next page
    case loaded
    case empty
    case failed(String)
    case endReached
}
```

## One-Liner
Load small pages on demand, debounce and cancel search, and never show stale results.
