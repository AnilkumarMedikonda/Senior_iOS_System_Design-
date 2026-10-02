# 03 - Prefetch Trigger

## Idea
Start loading the next page **before** the user hits the bottom, so scrolling never stops at a spinner.

```
Items:  1 ... 15 [16] 17 18 19 20
                  ▲
         row 16 appears → load page 2 (threshold = 5 from end)
```

## Code — SwiftUI

```swift
List(viewModel.items) { product in
    ProductRow(product: product)
        .onAppear {
            viewModel.loadMoreIfNeeded(current: product)
        }
}
```

```swift
private let threshold = 5

func loadMoreIfNeeded(current: Product) {
    guard let index = items.firstIndex(where: { $0.id == current.id }) else { return }
    if index >= items.count - threshold {
        loadNextPage()
    }
}
```

## Guards (Very Important)

```swift
func loadNextPage() {
    guard !isLoading, hasMore else { return }
    isLoading = true
    // request page...
}
```

| Guard | Prevents |
|-------|----------|
| `!isLoading` | Same page requested many times while scrolling |
| `hasMore` | Requests after the last page |
| Same query check | Old query's page appended to new results |

## Code — UIKit

```swift
func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    if indexPath.row >= items.count - threshold {
        viewModel.loadNextPage()
    }
}
```

`UITableViewDataSourcePrefetching` can also trigger it, plus prefetch images for upcoming rows.

## Footer States

| State | Footer |
|-------|--------|
| Loading more | Spinner |
| Load more failed | "Retry" button (keep loaded items) |
| End reached | "No more results" |

## Senior Point
A failed next page must **not** clear the list. Keep the items, show a retry footer, and retry the same page.

## One-Liner
Trigger near the end, guard with isLoading and hasMore, and keep the list on failure.
