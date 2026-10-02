# 02 - URL Parsing and Normalization

## Problem
The same screen arrives in many shapes:

```
https://shop.com/product/123
https://www.shop.com/Product/123/?utm_source=email
shop://product/123
shop://p/123                     (old format)
push: { "link": "/product/123" }
```

All of them must become → `.product(id: "123")`

## Normalization Steps

```
Raw URL
  │
  ├─ 1. Validate scheme / host   (https + shop.com/www.shop.com, or shop://)
  ├─ 2. Lowercase host + path, drop trailing "/"
  ├─ 3. Custom scheme: host becomes the first path segment
  ├─ 4. Split path into segments   ["product", "123"]
  ├─ 5. Map old aliases            "p" → "product"
  ├─ 6. Read query items           q, utm_campaign
  └─ 7. Match → DeepLink enum
```

## Code

```swift
final class DeepLinkParser {
    private let allowedHosts: Set<String> = ["shop.com", "www.shop.com"]
    private let aliases = ["p": "product", "c": "category"]

    func parse(_ url: URL) -> DeepLink? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        var segments = url.path.lowercased().split(separator: "/").map { String($0) }

        // 1. Scheme and host
        if url.scheme == "shop" {
            if let host = url.host?.lowercased() {
                segments.insert(host, at: 0)        // shop://product/123
            }
        } else if url.scheme == "https" {
            guard let host = url.host?.lowercased(), allowedHosts.contains(host) else { return nil }
        } else {
            return nil
        }

        // 2. Aliases
        if let first = segments.first, let real = aliases[first] {
            segments[0] = real
        }

        // 3. Match
        let query = components.queryItems?.first(where: { $0.name == "q" })?.value
        switch (segments.first, segments.count) {
        case (nil, _):
            return .home
        case ("product", 2):
            return .product(id: segments[1])
        case ("category", 2):
            return .category(slug: segments[1])
        case ("cart", 1):
            return .cart
        case ("order", 2):
            return .order(id: segments[1])
        case ("search", 1):
            if let query = query, !query.isEmpty {
                return .search(query: query)
            }
            return nil
        default:
            return nil
        }
    }
}
```

## Entry Points

| Source | SwiftUI | UIKit |
|--------|---------|-------|
| Universal Link | `.onOpenURL` | `scene(_:continue:)` → `userActivity.webpageURL` |
| Custom scheme | `.onOpenURL` | `scene(_:openURLContexts:)` |
| Cold start | `.onOpenURL` | `connectionOptions.urlContexts` / `.userActivities` |
| Push | `userNotificationCenter(_:didReceive:)` → payload link → URL |

## Universal Link Setup
- `apple-app-site-association` file hosted at `https://shop.com/.well-known/`
- Lists app ID + allowed paths (`/product/*`, `/order/*`)
- Xcode: Associated Domains → `applinks:shop.com`

## Senior Point
Validate the host for https links, because any website could otherwise open your routes. Never trust IDs from a URL: the target screen still loads and validates data from the server.

## One-Liner
Validate, lowercase, map aliases, split the path, and turn every URL shape into one DeepLink enum.
