# 01 - Requirements

## Big Picture

```
View → ViewModel → Repository → Local Store (source of truth)
                        │
                        └─► Mutation Queue → Sync Engine → Server
```

**Rule:** the UI never waits for the network. Write locally first, sync later.

## Functional
- Create, edit, complete and delete todos while offline
- Show changes instantly, without waiting for the server
- Sync changes automatically when the network returns
- Show the sync state per item (synced / pending / failed)

## Non-Functional
- Data survives app kill and relaunch
- No lost changes, no duplicate creates on the server
- Changes sent in the order they were made
- Retry with backoff, without draining battery

## Out of Scope
- Real-time collaboration
- Sharing todos between users

## Clarifying Questions to Ask
- Can the same data be edited on two devices?
- Who wins in a conflict: server, latest edit, or the user?
- How long can a user stay offline?
- How large is the data set? Full sync or delta sync?

## Models

```swift
struct Todo: Codable, Identifiable {
    let id: UUID
    var title: String
    var isDone: Bool
    var updatedAt: Date
    var syncStatus: SyncStatus
}

enum SyncStatus: String, Codable {
    case synced
    case pending
    case failed
}
```

## One-Liner
The app must work fully offline and never lose or duplicate a change.
