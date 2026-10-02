# 05 - Fallback and Unknown Routes

## Rule
A bad link must **never** crash the app or leave the user on a blank screen.

## Failure Cases

| Case | Example | Fallback |
|------|---------|----------|
| Unknown path | `shop.com/blog/abc` | Open in Safari (web page exists) or Home |
| Missing / bad param | `shop://product/` | Home + optional toast |
| Item not found | `.product("999")` → 404 | Product screen shows "Not available" + Back |
| Needs login | `.order("A1")`, logged out | Login → then continue |
| Unsupported in this version | New route, old app | Home + "Update app" prompt |
| Untrusted host | `https://evil.com/product/1` | Ignore |

## Code

```swift
extension AppRouter {
    func handleUnknown(_ url: URL) {
        print("DEEPLINK: unknown \(url.absoluteString)")
        // Our website → let Safari show it
        if url.scheme == "https", let host = url.host, host.hasSuffix("shop.com") {
            UIApplication.shared.open(url)
            return
        }
        // Anything else → Home
        handle(.home)
    }
}
```

## Not Found Is Handled by the Screen
The router can't know whether product 999 exists. The screen loads it and shows a proper empty/error state, so the deep link layer stays simple.

## Analytics
Log every link with its result:

```
deeplink_opened   source=push  route=product  campaign=diwali_sale
deeplink_failed   source=universal  url=/blog/abc  reason=unknown_route
```

This finds broken marketing links fast.

## Full Flow

```
URL / push arrives
   │
   ├─ Parser: valid host? known route? params ok?
   │      └─ no → handleUnknown → Safari or Home
   │
   ├─ App ready?
   │      └─ no → pendingLink, wait for appDidBecomeReady()
   │
   ├─ Router: requires login and logged out?
   │      └─ yes → Login → didLogin() → continue
   │
   ├─ Dismiss modals → switch tab → reset stack → push screen
   │
   └─ Screen loads data → 404 → "Not available" state
```

## Testing Checklist
- Every route from cold start and warm start
- Logged in and logged out
- Malformed, unknown and old-format URLs
- `xcrun simctl openurl booted "shop://product/123"` for quick tests

## Senior Point
Separate failures by layer: the parser rejects bad URLs, the router handles auth and navigation, and the screen handles missing data. Each layer stays simple and testable.

## One-Liner
Unknown links go to Safari or Home, auth routes go through Login, missing data is the screen's job, and every failure is logged.
