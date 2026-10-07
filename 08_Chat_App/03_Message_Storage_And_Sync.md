# 03 - Message Storage and Sync

## Local Database = Source of Truth

```
WebSocket event ─┐
REST history    ─┼──► upsert into SwiftData ──► ChatView redraws
Outbox send     ─┘
```

The view never renders socket events directly → same code path for live, history and offline.

## Ordering — Server Sequence, Not Device Time

| Sort by | Problem |
|---------|---------|
| Device `createdAt` | Clocks differ between phones → wrong order |
| **Server `seq`** (per conversation) | Assigned by the server in one order ✅ |

Pending messages (no `seq` yet) are shown **at the bottom**, ordered by `createdAt`, until the ack gives them a `seq`.

```swift
// Sort: confirmed by seq, pending last
messages.sorted {
    switch ($0.seq, $1.seq) {
    case let (a?, b?): return a < b
    case (_?, nil):    return true
    case (nil, _?):    return false
    case (nil, nil):   return $0.createdAt < $1.createdAt
    }
}
```

## De-Duplication (Upsert)
The same message can arrive twice: socket + catch-up, or ack + echo.

```
Incoming message
   ├─ has clientID I already store? → update it (my own message echoed back)
   ├─ has serverID I already store? → ignore / update status
   └─ else → insert
```

Unique keys: `clientID` (own messages) and `serverID` (everyone's).

## Gap Detection

```
Local lastSeq = 40
Socket delivers seq 43
   → 41, 42 missing → GET /conversations/c1/messages?after=40
```

## Sync After Reconnect

```
connected
  → for each open conversation: GET /messages?after=lastSeq
  → upsert all → update lastSeq
  → flush outbox (04)
```

For many conversations, one `GET /sync?since=globalCursor` returns all changes across chats.

## History — Cursor Pagination (04 Pagination)

```
Open chat → show last 50 from DB instantly
Scroll to top → GET /messages?before=<oldest seq>&limit=50 → insert → keep scroll position
hasMore = response.count == 50
```

Cursor (seq), not offset: new messages arrive constantly, so offset would shift.

## Conversation List
- Updated by every inserted message: `lastMessage`, `lastSeq`, `unreadCount`
- Sorted by last activity
- Unread = messages from others with `seq > lastReadSeq`

## Senior Point
Order by server sequence, upsert by clientID/serverID, and detect gaps by sequence numbers. With those three, duplicates, reordering and missed messages all become simple to handle.

## One-Liner
Everything goes into the local DB first; order by server seq, upsert to de-dupe, fill gaps and catch up with after=lastSeq, and page history with before=seq.
