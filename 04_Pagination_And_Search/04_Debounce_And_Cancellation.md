# 04 - Debounce and Cancellation

## Problem
The user types "iphone":

```
i → ip → iph → ipho → iphon → iphone
6 keystrokes = 6 requests → wasted calls, rate limits,
and a slow old response ("iph") can arrive LAST and overwrite "iphone"
```

## 1. Debounce — Wait Until Typing Stops

```
i  ip  iph  ipho  iphon  iphone ......(400ms)...... → 1 request
```

Without Combine, use `DispatchWorkItem`:

```swift
private var debounceWork: DispatchWorkItem?

func searchTextChanged(_ text: String) {
    debounceWork?.cancel()
    let work = DispatchWorkItem { [weak self] in
        self?.startSearch(text)
    }
    debounceWork = work
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
}
```

## 2. Cancellation — Stop the Old Request

```swift
private var currentTask: URLSessionDataTask?

func startSearch(_ text: String) {
    currentTask?.cancel()
    currentTask = repository.search(text, skip: 0) { [weak self] result in
        // handle result
    }
}
```

## 3. Stale Response Guard — Last Line of Defense
Cancel can lose the race: the response may already be on its way. Tag every request with its query.

```swift
private var activeQuery = ""

func startSearch(_ text: String) {
    activeQuery = text
    repository.search(text, skip: 0) { [weak self] result in
        guard let self = self, text == self.activeQuery else { return }   // stale → ignore
        // apply result
    }
}
```

## Extra Rules
- Trim spaces; ignore empty or 1-character queries
- Same text as the current query → don't search again
- Clearing the search → cancel and show the normal list
- New query → reset `items`, `skip`, `hasMore`

## Timeline

```
t=0      type "iph"     → debounce starts
t=200ms  type "iphone"  → debounce restarts
t=600ms  search "iphone" sent
t=700ms  type "iphone 15" → cancel "iphone", debounce restarts
t=1100ms search "iphone 15" sent → only this result is shown
```

## Senior Point
Debounce reduces requests, cancellation saves bandwidth, and the query check guarantees correctness. You need all three.

## One-Liner
Debounce the typing, cancel the old request, and ignore any response whose query is no longer active.
