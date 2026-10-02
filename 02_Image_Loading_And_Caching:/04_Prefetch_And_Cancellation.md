# 04 - Prefetch and Cancellation

## Problems During Fast Scrolling
- Loads keep running for cells already off-screen, wasting bandwidth
- Reused cells show the **wrong image** when an old load finishes late
- The same URL gets downloaded twice when two views ask at once

## 1. Cancellation — Per Request

Each caller gets a `UUID`. The download is cancelled only when **no one** is waiting.

```swift
func cancel(_ url: URL, id: UUID) {
    queue.async {
        guard var list = self.waiters[url] else { return }
        list[id] = nil
        if list.isEmpty {
            self.tasks[url]?.cancel()
            self.tasks[url] = nil
            self.waiters[url] = nil
        } else {
            self.waiters[url] = list
        }
    }
}
```

| SwiftUI | UIKit |
|---------|-------|
| `onDisappear { viewModel.cancel() }` | `prepareForReuse()` → cancel |

## 2. De-Duplication — One Download per URL

```
View A: load(url) → no task → start download, waiters[url] = [A]
View B: load(url) → task exists → join, waiters[url] = [A, B]
Download done → save disk → complete A and B
```

```swift
if var list = self.waiters[url] {
    list[id] = waiter
    self.waiters[url] = list
    return
}
```

## 3. Wrong Image Fix (UIKit)

```swift
currentURL = url
requestID = ImageLoader.shared.load(url, maxPixel: maxPixel) { [weak self] image in
    guard let self = self, self.currentURL == url else { return }
    self.imageView.image = image
}
```

SwiftUI doesn't need this check, because each `RemoteImageView` has its own identity and ViewModel per item.

## 4. Prefetch

| SwiftUI | UIKit |
|---------|-------|
| `LazyVGrid` creates views just before they appear | `prefetchItemsAt` starts loads early |
| — | `cancelPrefetchingForItemsAt` cancels them |

## Thread Safety
`tasks` and `waiters` are only read and written on **one serial queue**, so no locks are needed.

## Senior Point
Cancel per caller, not per URL. Otherwise one cell scrolling away cancels the image another visible cell still needs.

## One-Liner
Prefetch what's coming, cancel what's gone, share one download per URL, and check the URL before setting the image.
