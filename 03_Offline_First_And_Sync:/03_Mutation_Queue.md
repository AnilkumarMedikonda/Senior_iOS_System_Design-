# 03 - Mutation Queue

## Idea
Every local change becomes a **Mutation** saved to disk. The queue survives app kills and is sent in order when online.

```
[create A] → [update A] → [delete B] → ...   (FIFO)
```

## Model

```swift
struct Mutation: Codable, Identifiable {
    let id: UUID              // idempotency key
    let type: MutationType
    let todo: Todo
    let createdAt: Date
    var attempts: Int
}

enum MutationType: String, Codable {
    case create
    case update
    case delete
}
```

## Code

```swift
final class MutationQueue {
    private var items: [Mutation] = []
    private let fileURL = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("mutations.json")

    func enqueue(_ type: MutationType, todo: Todo) {
        items.append(Mutation(id: UUID(), type: type, todo: todo, createdAt: Date(), attempts: 0))
        persist()
    }

    func peek() -> Mutation? {
        return items.first
    }

    func removeFirst() {
        items.removeFirst()
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(items) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}
```

## Collapsing (Squashing)
Merge changes to the same item before sending, so there are fewer requests:

| Queue Has | New Change | Result |
|-----------|------------|--------|
| create A | update A | create A (with new data) |
| create A | delete A | remove both (server never knew) |
| update A | update A | one update (latest data) |
| update A | delete A | delete A |

## Idempotency
`Mutation.id` is sent as an `Idempotency-Key` header. If a retry reaches the server twice, the server ignores the duplicate, so a create is never doubled.

## Senior Point
Persist the queue **before** sending. If the app is killed mid-request, the mutation is retried on the next launch, and idempotency makes that safe.

## One-Liner
Save every change as a mutation, collapse duplicates, and send FIFO with an idempotency key.
