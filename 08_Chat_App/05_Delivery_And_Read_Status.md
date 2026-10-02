# 05 - Delivery and Read Status

## The Four Stages

```
Sender                     Server                     Recipient
  │ send (clientID)          │                            │
  │─────────────────────────►│ store, assign seq          │
  │◄──── ack: sent ✓ ────────│                            │
  │                          │──── message.new ──────────►│ stored in DB
  │                          │◄─── receipt: delivered ────│
  │◄── delivered ✓✓ ─────────│                            │
  │                          │                            │ user opens chat
  │                          │◄─── receipt: read ─────────│
  │◄── read ✓✓ (blue) ───────│                            │
```

| Status | Who sets it | When |
|--------|-------------|------|
| sent | Server ack | Server stored the message |
| delivered | Recipient device | Message saved to the recipient's local DB |
| read | Recipient device | Chat visible on screen |

## Watermarks, Not Per-Message Receipts

Sending a receipt for every message wastes traffic. Send **one number per conversation**:

```json
{ "type": "receipt", "conversationID": "c1", "deliveredSeq": 57, "readSeq": 55 }
```

Meaning: everything up to seq 57 delivered, up to 55 read. The sender marks all its messages with `seq <= 55` as read.

```swift
func applyReceipt(conversationID: String, deliveredSeq: Int, readSeq: Int) {
    for message in store.myMessages(in: conversationID) {
        guard let seq = message.seq else { continue }
        if seq <= readSeq {
            message.status = .read
        } else if seq <= deliveredSeq, message.status == .sent {
            message.status = .delivered
        }
    }
}
```

## When to Send Receipts
- **Delivered**: right after a new message is saved locally (batch for ~1s)
- **Read**: when the chat is visible and the app is in foreground; send the highest visible seq
- Throttle: at most one read receipt every ~2s per conversation
- Status only moves **forward**: sent → delivered → read, never back

## Unread Count

```
unreadCount = messages from others with seq > lastReadSeq
Open chat → lastReadSeq = newest seq → unread 0 → send read receipt
```

`lastReadSeq` also syncs across the user's own devices → read on iPad clears the badge on iPhone.

## Typing Indicator
- Ephemeral: never stored, never queued offline
- Send `typing` at most every 3s while typing; receiver hides it after 5s without updates

## Background — Push Notifications
- Socket is closed in background → server sends **APNs push** for new messages
- Tapping the push → deep link (05) to the conversation → socket connects → catch-up sync
- Notification Service Extension can mark "delivered" and update the badge

## Groups (Extension)
- Per-member watermarks → "Read by 3 of 5"
- Large groups: no per-member receipts, only counts

## Full Flow

```
Type → optimistic insert (.sending) → outbox → socket send
   → ack → .sent (✓)
   → recipient stores → delivered watermark → ✓✓
   → recipient opens chat → read watermark → ✓✓ blue
Socket drops → backoff reconnect → catch-up after=lastSeq → flush outbox
App in background → push → tap → deep link → reconnect → sync
```

## Senior Point
Use per-conversation sequence watermarks for delivered and read instead of per-message receipts: one small event updates any number of messages, and statuses only move forward.

## One-Liner
Sent comes from the server ack, delivered and read come from recipient watermarks by seq, typing is ephemeral, and push covers the background.
