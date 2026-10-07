# 02 - WebSocket Connection

## Why WebSocket
HTTP is request → response. Chat needs the **server to push** to the client anytime. A WebSocket is one long-lived, two-way connection.

| Option | Real-time | Battery | Use |
|--------|-----------|---------|-----|
| Polling every N s | Poor | Bad | ❌ |
| Long polling | OK | Medium | Fallback |
| **WebSocket** | Excellent | Good in foreground | ✅ Chat |
| Push notifications | Delayed | Best | App in background |

## Connection State Machine

```
disconnected ──connect()──► connecting ──open──► connected
     ▲                           │                   │
     │                        failure          close / error / ping timeout
     │                           ▼                   ▼
     └──── wait backoff ◄── reconnecting ◄───────────┘
```

## Event Envelope (JSON)

```json
{ "type": "message.send",    "clientID": "uuid", "conversationID": "c1", "text": "Hi" }
{ "type": "message.ack",     "clientID": "uuid", "serverID": "m88", "seq": 42 }
{ "type": "message.new",     "serverID": "m89", "seq": 43, "conversationID": "c1", "senderID": "u2", "text": "Hello" }
{ "type": "receipt",         "conversationID": "c1", "userID": "u2", "deliveredSeq": 42, "readSeq": 42 }
{ "type": "typing",          "conversationID": "c1", "userID": "u2" }
```

One `type` field → one decoder switch. Unknown types are ignored (forward compatible).

## Code — URLSessionWebSocketTask

```swift
final class SocketConnection {
    private var task: URLSessionWebSocketTask?
    private var pingTimer: Timer?
    private var attempt = 0
    var onEvent: ((Data) -> Void)?
    var onStateChange: ((Bool) -> Void)?

    func connect(token: String) {
        var request = URLRequest(url: URL(string: "wss://chat.example.com/ws")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        task = URLSession.shared.webSocketTask(with: request)
        task?.resume()
        receive()
        startPing()
    }

    private func receive() {
        task?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(.string(let text)):
                self.attempt = 0
                self.onEvent?(Data(text.utf8))
                self.receive()                      // keep listening
            case .success:
                self.receive()
            case .failure:
                self.scheduleReconnect()
            }
        }
    }

    func send(_ data: Data) {
        task?.send(.string(String(decoding: data, as: UTF8.self))) { error in
            if error != nil { self.scheduleReconnect() }
        }
    }

    private func startPing() {
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 25, repeats: true) { [weak self] _ in
            self?.task?.sendPing { error in
                if error != nil { self?.scheduleReconnect() }
            }
        }
    }

    private func scheduleReconnect() {
        task?.cancel(with: .goingAway, reason: nil)
        onStateChange?(false)
        attempt += 1
        let base = min(pow(2.0, Double(attempt)), 30)
        let jitter = Double.random(in: 0...1)
        DispatchQueue.main.asyncAfter(deadline: .now() + base + jitter) {
            // reconnect with a fresh token
        }
    }
}
```

## Lifecycle Rules
- **Foreground** → connect; **background** → disconnect (iOS suspends sockets anyway) → push takes over
- **Network back** (`NWPathMonitor`) → reconnect immediately, reset backoff
- **Ping every ~25s** → detects dead connections and keeps NAT/proxies from closing it
- **Auth**: token in the handshake header; on 401 → refresh token (06) → reconnect
- **After every reconnect → catch up** with `GET ...?after=lastSeq` (messages sent while disconnected)

## Senior Point
A WebSocket gives **no delivery guarantee**. Anything sent while the socket was "connected" but actually dead is lost, which is why every send needs an ack, and every reconnect needs a catch-up sync.

## One-Liner
One socket in foreground with ping, exponential backoff + jitter on drop, push in background, and a catch-up sync after every reconnect.
