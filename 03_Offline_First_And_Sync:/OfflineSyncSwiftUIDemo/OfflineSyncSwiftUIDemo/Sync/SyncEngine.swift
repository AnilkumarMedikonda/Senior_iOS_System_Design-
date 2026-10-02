//
//  SyncEngine.swift
//  OfflineSyncSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation
import SwiftData

final class SyncEngine {
    private let context: ModelContext
    private let api: FakeTodoAPI
    private let monitor: NetworkMonitor
    private var isSyncing = false
    private let maxAttempts = 5
    private(set) var inFlightID: UUID?
    var onChange: (() -> Void)?

    init(context: ModelContext, api: FakeTodoAPI, monitor: NetworkMonitor) {
        self.context = context
        self.api = api
        self.monitor = monitor
        monitor.onStatusChange = { [weak self] online in
            if online {
                self?.syncNext()
            }
        }
        monitor.start()
    }

    var canSync: Bool {
        return monitor.isOnline && !api.isOfflineMode
    }

    func syncNext() {
        // 1. One at a time
        guard canSync, !isSyncing, let mutation = oldestMutation() else { return }
        isSyncing = true
        inFlightID = mutation.id
        let request = MutationRequest(mutation)
        print("SYNC: sending \(request.type.rawValue) \(request.title) (attempt \(mutation.attempts + 1))")

        api.send(request) { [weak self] result in
            guard let self = self else { return }
            self.inFlightID = nil
            switch result {
            case .success:
                // 2. Remove only after server confirms
                self.context.delete(mutation)
                self.markTodo(request.todoID, as: .synced)
                self.save()
                self.isSyncing = false
                self.syncNext()
            case .failure(.offline):
                // 3. Offline — stop, wait for network or toggle
                print("SYNC: offline, paused")
                self.isSyncing = false
                self.onChange?()
            case .failure(.server(let code)):
                // 4. Server error — retry with backoff
                mutation.attempts += 1
                if mutation.attempts >= self.maxAttempts {
                    print("SYNC: gave up on \(request.title)")
                    self.context.delete(mutation)
                    self.markTodo(request.todoID, as: .failed)
                    self.save()
                    self.isSyncing = false
                    self.syncNext()
                    return
                }
                self.save()
                let delay = min(pow(2.0, Double(mutation.attempts)), 60)
                print("SYNC: \(code), retry in \(Int(delay))s")
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self.isSyncing = false
                    self.syncNext()
                }
            }
        }
    }

    // MARK: - Helpers

    private func oldestMutation() -> PendingMutation? {
        var descriptor = FetchDescriptor<PendingMutation>(sortBy: [SortDescriptor(\.createdAt)])
        descriptor.fetchLimit = 1
        if let result = try? context.fetch(descriptor) {
            return result.first
        } else {
            return nil
        }
    }

    private func markTodo(_ id: UUID, as status: SyncStatus) {
        // Still pending if more mutations exist for this todo
        let pending = FetchDescriptor<PendingMutation>(predicate: #Predicate { $0.todoID == id })
        if status == .synced, let count = try? context.fetchCount(pending), count > 0 {
            return
        }
        let descriptor = FetchDescriptor<Todo>(predicate: #Predicate { $0.id == id })
        if let todo = try? context.fetch(descriptor).first {
            todo.syncStatus = status
        }
    }

    private func save() {
        try? context.save()
        onChange?()
    }
}
