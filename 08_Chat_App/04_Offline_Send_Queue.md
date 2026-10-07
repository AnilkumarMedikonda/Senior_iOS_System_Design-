# 04 - Offline Send Queue (Outbox)

## Flow

```
User taps Send
  1. Create Message(clientID: UUID, status: .sending) → insert in DB → shows instantly (optimistic)
  2. Add to Outbox (persisted)
  3. Socket connected? → send { clientID, text }
  4. Server stores it → ack { clientID, serverID, seq }
  5. Update message: serverID, seq, status = .sent → remove from Outbox
```

## Why clientID
- Created **on the device**, before the server knows anything
- Links the ack back to the right local message
- Acts as the **idempotency key**: if a retry reaches the server twice, the server returns the same message instead of creating a duplicate

## Outbox Rules (same as 03 Offline First)

| Rule | Why |
|------|-----|
| Persist outbox in DB | Survives app kill |
| FIFO per conversation | "Hi" must arrive before "How are you?" |
| Remove only on ack | Socket send ≠ delivered |
| Ack timeout (~10s) → resend same clientID | Covers dead sockets |
| Backoff on failures | Don't hammer the server |
| After N attempts → `.failed` | Show red "!" → tap to retry |
| Socket down → fall back to `POST /messages` | Optional, same clientID |

## Code

```swift
final class Outbox {
    private var pending: [Message] = []      // persisted in SwiftData in real app
    private var inFlight: Set<UUID> = []
    private let ackTimeout: TimeInterval = 10

    func enqueue(_ message: Message) {
        pending.append(message)
        flush()
    }

    func flush() {
        guard socket.isConnected else { return }
        for message in pending where !inFlight.contains(message.clientID) {
            inFlight.insert(message.clientID)
            socket.send(.messageSend(message))
            DispatchQueue.main.asyncAfter(deadline: .now() + ackTimeout) { [weak self] in
                self?.ackTimedOut(message.clientID)
            }
        }
    }

    func didReceiveAck(clientID: UUID, serverID: String, seq: Int) {
        pending.removeAll { $0.clientID == clientID }
        inFlight.remove(clientID)
        store.markSent(clientID: clientID, serverID: serverID, seq: seq)
    }

    private func ackTimedOut(_ clientID: UUID) {
        guard inFlight.contains(clientID) else { return }     // already acked
        inFlight.remove(clientID)
        flush()                                                // resend, same clientID
    }
}
```

## Status in the UI

| Status | Icon |
|--------|------|
| `.sending` | 🕓 clock |
| `.sent` | ✓ |
| `.delivered` | ✓✓ |
| `.read` | ✓✓ (blue) |
| `.failed` | ❗ tap to retry |

## Senior Point
The ack is the only proof of delivery to the server. Keep the message in the outbox until the ack arrives, resend with the same clientID on timeout, and let the server de-dupe.

## One-Liner
Optimistic insert with a device clientID, persistent FIFO outbox, remove only on ack, resend with the same clientID, and the server de-dupes.
