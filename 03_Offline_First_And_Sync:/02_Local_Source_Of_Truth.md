# 02 - Local Source of Truth

## Idea
The View reads **only** from the local store. The server updates the local store, and the local store updates the UI.

```
Server ──► Local Store ──► View
User   ──► Local Store ──► View   (+ queue mutation)
```

## Storage Options

| Option | Good For |
|--------|----------|
| Core Data / SwiftData | Large data, relationships, queries |
| SQLite (GRDB) | Full control, performance |
| JSON file (demo) | Small data, simple to explain |

## Code

```swift
final class LocalStore {
    private let fileURL = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("todos.json")

    func load() -> [Todo] {
        guard let data = try? Data(contentsOf: fileURL),
              let todos = try? JSONDecoder().decode([Todo].self, from: data) else { return [] }
        return todos
    }

    func save(_ todos: [Todo]) {
        if let data = try? JSONEncoder().encode(todos) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}
```

## Repository Write Flow

```swift
func toggle(_ todo: Todo) {
    var updated = todo
    updated.isDone.toggle()
    updated.updatedAt = Date()
    updated.syncStatus = .pending
    store.update(updated)                       // 1. local first
    queue.enqueue(.update, todo: updated)       // 2. remember change
    syncEngine.syncIfPossible()                 // 3. try now
}
```

## Senior Point
Use the **Documents** directory, not Caches, because user data must never be cleared by the system. Use `.atomic` writes so a crash can't leave a half-written file.

## One-Liner
The UI trusts only the local store; the network is just a background update channel.
