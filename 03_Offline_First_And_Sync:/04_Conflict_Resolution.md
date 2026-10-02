# 04 - Conflict Resolution

## When It Happens
The same item is changed on **two devices** (or on the server) while one is offline.

```
Phone (offline): title = "Buy milk"      updatedAt 10:05
Web:             title = "Buy oat milk"  updatedAt 10:03
Phone comes online → which one wins?
```

## Strategies

| Strategy | How | Good For |
|----------|-----|----------|
| Last Write Wins | Latest `updatedAt` wins | Todos, settings |
| Server Wins | Server always wins, local is discarded | Prices, inventory |
| Client Wins | Local always overwrites | Single-device data |
| Field Merge | Merge per field (title vs isDone) | Forms, profiles |
| Ask User | Show both versions | Documents, notes |

## Detecting Conflicts — Version Check
- Each item has a `version` from the server
- The client sends its version with an update
- Server version is newer → **409 Conflict** + server copy → resolve locally

```swift
func resolve(local: Todo, server: Todo) -> Todo {
    // Last Write Wins
    if local.updatedAt > server.updatedAt {
        return local          // re-send local
    } else {
        var winner = server
        winner.syncStatus = .synced
        return winner         // overwrite local
    }
}
```

## Senior Point
Device clocks can be wrong, so in production use **server timestamps or version numbers**, not the device's `Date()`. Pick the strategy per data type, not one rule for the whole app.

## One-Liner
Detect conflicts with versions, then resolve per data type: last-write-wins for simple data, server-wins for critical data.
