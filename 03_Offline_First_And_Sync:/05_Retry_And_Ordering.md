# 05 - Retry and Ordering

## When to Sync
- App launch and foreground
- Network comes back (`NWPathMonitor`)
- Right after a local change (if online)
- Background refresh (`BGAppRefreshTask`) for long offline periods

## Ordering
- Send **one mutation at a time**, oldest first
- Never send `update A` before `create A`
- Remove from the queue **only after** the server confirms

```
peek() → send → 200 → removeFirst() → next
              → fail → stop, retry later (keep order)
```

## Retry Rules

| Error | Action |
|-------|--------|
| No internet / timeout | Stop, wait for network |
| 5xx / 429 | Retry with backoff: 2s, 4s, 8s ... max 60s |
| 409 Conflict | Resolve, then continue |
| 4xx (bad data) | Mark `.failed`, remove from queue, show to user |
| attempts > 5 | Mark `.failed`, move on |

## Code

```swift
func syncNext() {
    guard isOnline, !isSyncing, let mutation = queue.peek() else { return }
    isSyncing = true
    api.send(mutation) { [weak self] result in
        guard let self = self else { return }
        self.isSyncing = false
        switch result {
        case .success:
            self.queue.removeFirst()
            self.store.markSynced(mutation.todo.id)
            self.syncNext()
        case .failure:
            self.queue.incrementAttempts()
            let delay = min(pow(2.0, Double(mutation.attempts + 1)), 60)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.syncNext()
            }
        }
    }
}
```

## Network Monitoring

```swift
let monitor = NWPathMonitor()
monitor.pathUpdateHandler = { path in
    self.isOnline = (path.status == .satisfied)
    if self.isOnline { self.syncNext() }
}
monitor.start(queue: DispatchQueue(label: "network.monitor"))
```

## Full Flow

```
User taps "Done" (offline)
   ├─ 1. Local Store updated → .pending
   ├─ 2. Mutation(.update) queued
   ├─ 3. View updates instantly
Network back
   ├─ 4. Send oldest mutation
   ├─ 5. 200 → remove → .synced
   └─ 6. Fail → attempts += 1 → backoff
```

## Senior Point
`isSyncing` prevents two sync loops from running at once. Without it, the same mutation can be sent twice and the order can break.

## One-Liner
One at a time, oldest first, remove only on success, and back off on failure.
