# 01 - Requirements

## Big Picture

```
ChatView ◄── observes ── Local DB (SwiftData)  ← source of truth (03 Offline First)
   │                          ▲
   │ send                     │ insert / update
   ▼                          │
Outbox (offline queue) ──► ChatClient ──► WebSocket  ⇄  Chat Server
                              │                         │
                              └── REST: history, sync   │
                                                        └─► Push (app in background)
```

**Rule:** the UI only reads the local database. WebSocket and REST just write into it.

## Functional
- 1:1 chats (groups as an extension)
- Send and receive text messages in real time
- Conversation list with last message and unread count
- Load older messages by scrolling up (pagination)
- Send while offline; messages go out when back online
- Message status: sending → sent → delivered → read
- Typing indicator
- Push notification when the app is in the background

## Non-Functional
- Real-time: message appears in < 1s when both are online
- No lost messages, no duplicates, correct order
- Works offline: read history, write messages
- Reconnects automatically after network drops
- Battery friendly: socket only in foreground, push in background

## Out of Scope
- Media upload (images/video), voice/video calls
- End-to-end encryption (mention as extension)

## Clarifying Questions to Ask
- 1:1 only or groups? Max group size?
- Must messages sync across multiple devices?
- How long is history kept? Search needed?
- Is end-to-end encryption required?

## Models

```swift
enum MessageStatus: String, Codable {
    case sending        // in outbox, not acked
    case sent           // server stored it
    case delivered      // recipient device got it
    case read           // recipient opened the chat
    case failed         // gave up, tap to retry
}

struct Message: Codable, Identifiable {
    let clientID: UUID          // created on device → idempotency + local id
    var serverID: String?       // set after server ack
    var seq: Int?               // server order within the conversation
    let conversationID: String
    let senderID: String
    let text: String
    let createdAt: Date
    var status: MessageStatus

    var id: UUID { clientID }
}

struct Conversation: Codable, Identifiable {
    let id: String
    let title: String
    var lastMessage: String?
    var lastSeq: Int            // newest server seq stored locally
    var lastReadSeq: Int        // read watermark
    var unreadCount: Int
}
```

## API Contract

| Channel | Use |
|---------|-----|
| `wss://chat.example.com/ws` | Real-time events (send, receive, acks, receipts, typing) |
| `GET /conversations` | List |
| `GET /conversations/{id}/messages?before=seq&limit=50` | Older history (cursor) |
| `GET /conversations/{id}/messages?after=seq` | Catch up after reconnect |
| `POST /messages` | Fallback send when socket is down |

## One-Liner
Local DB is the truth, WebSocket for real time, REST for history and catch-up, and a persistent outbox so no message is ever lost.
