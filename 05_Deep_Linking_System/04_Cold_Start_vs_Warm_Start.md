# 04 - Cold Start vs Warm Start

## The Difference

| | Cold Start | Warm Start |
|---|-----------|-----------|
| App state | Killed, launching from zero | In background, UI already exists |
| UI ready? | No: splash, config, auth restore | Yes |
| Risk | Link handled too early → lost or crash | Link must replace current screen state |
| UIKit entry | `scene(_:willConnectTo:options:)` → `connectionOptions` | `scene(_:openURLContexts:)` / `scene(_:continue:)` |
| SwiftUI entry | `.onOpenURL` (fires after first scene appears) | `.onOpenURL` |

## The Problem on Cold Start

```
Launch → link arrives → router.handle(link)
                           ✗ tab bar not built
                           ✗ session not restored → wrong "requires login"
                           ✗ remote config not loaded
Result: link ignored, wrong screen, or crash
```

## The Fix — Pending Link

Store the link, and handle it only when the app says **"ready"**.

```swift
final class DeepLinkHandler {
    private let parser = DeepLinkParser()
    private let router: AppRouter
    private var pendingLink: DeepLink?
    private var isAppReady = false

    init(router: AppRouter) {
        self.router = router
    }

    func open(_ url: URL) {
        guard let link = parser.parse(url) else {
            router.handleUnknown(url)
            return
        }
        if isAppReady {
            router.handle(link)             // warm start
        } else {
            pendingLink = link              // cold start → wait
        }
    }

    func appDidBecomeReady() {
        isAppReady = true
        if let link = pendingLink {
            pendingLink = nil
            router.handle(link)
        }
    }
}
```

## Cold Start Timeline

```
t=0     App launches with link → pendingLink = .order("A1")
t=0.3   Splash, restore session from Keychain
t=0.8   Remote config loaded, root TabView built
t=0.9   appDidBecomeReady() → router.handle(.order("A1"))
        → logged in → Account tab → Orders → OrderDetail
```

## Warm Start Rules
- Dismiss any presented sheet or modal first
- Reset the target tab's stack, then push
- If the user is mid-checkout, finish or confirm before leaving (optional rule)

## Senior Point
Only **one** pending link is kept (the latest). Readiness means session restored + root UI built, not just `didFinishLaunching`. Test cold start by killing the app and opening the link from Notes or Safari.

## One-Liner
On cold start, store the link and handle it when the app is ready; on warm start, dismiss modals, reset the stack, and navigate.
