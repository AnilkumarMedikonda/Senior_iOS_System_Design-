//
//  TodoRepository.swift
//  OfflineSyncSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation
import SwiftData

final class TodoRepository {
    private let context: ModelContext
    private let syncEngine: SyncEngine

    init(context: ModelContext, syncEngine: SyncEngine) {
        self.context = context
        self.syncEngine = syncEngine
    }

    // MARK: - Read (local only)

    func fetchAll() -> [Todo] {
        let descriptor = FetchDescriptor<Todo>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        if let todos = try? context.fetch(descriptor) {
            return todos
        } else {
            return []
        }
    }

    func pendingCount() -> Int {
        if let count = try? context.fetchCount(FetchDescriptor<PendingMutation>()) {
            return count
        } else {
            return 0
        }
    }

    // MARK: - Write (local first → queue → sync)

    func add(title: String) {
        let todo = Todo(title: title)
        context.insert(todo)
        enqueue(.create, todo: todo)
        commit()
    }

    func toggle(_ todo: Todo) {
        todo.isDone.toggle()
        todo.updatedAt = Date()
        todo.syncStatus = .pending
        enqueue(.update, todo: todo)
        commit()
    }

    func delete(_ todo: Todo) {
        enqueue(.delete, todo: todo)    // snapshot before delete
        context.delete(todo)
        commit()
    }

    // MARK: - Queue with collapsing

    private func enqueue(_ type: MutationType, todo: Todo) {
        guard let existing = latestQueued(for: todo.id) else {
            context.insert(PendingMutation(type: type, todo: todo))
            return
        }
        switch (existing.type, type) {
        case (.create, .update):
            // Still a create, with the latest data
            copySnapshot(from: todo, to: existing)
        case (.create, .delete):
            // Server never knew → drop both
            context.delete(existing)
        case (.update, .update):
            copySnapshot(from: todo, to: existing)
        case (.update, .delete):
            existing.type = .delete
            copySnapshot(from: todo, to: existing)
        default:
            context.insert(PendingMutation(type: type, todo: todo))
        }
    }

    private func latestQueued(for id: UUID) -> PendingMutation? {
        let descriptor = FetchDescriptor<PendingMutation>(
            predicate: #Predicate { $0.todoID == id },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        guard let list = try? context.fetch(descriptor) else { return nil }
        for mutation in list {
            if mutation.id != syncEngine.inFlightID {
                return mutation
            }
        }
        return nil
    }

    private func copySnapshot(from todo: Todo, to mutation: PendingMutation) {
        mutation.title = todo.title
        mutation.isDone = todo.isDone
        mutation.updatedAt = todo.updatedAt
    }

    private func commit() {
        try? context.save()
        syncEngine.syncNext()
    }
}
