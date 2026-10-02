//
//  TodoListViewModel.swift
//  OfflineSyncSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation
import SwiftData
import Observation

@Observable
final class TodoListViewModel {
    private(set) var todos: [Todo] = []
    private(set) var pendingCount = 0
    var newTitle = ""
    var isOfflineMode = false {
        didSet {
            api.isOfflineMode = isOfflineMode
            print("TOGGLE: offline mode \(isOfflineMode ? "ON" : "OFF")")
            if !isOfflineMode {
                syncEngine.syncNext()
            }
        }
    }
    private let api: FakeTodoAPI
    private let syncEngine: SyncEngine
    private let repository: TodoRepository

    init(context: ModelContext) {
        let api = FakeTodoAPI()
        let monitor = NetworkMonitor()
        let syncEngine = SyncEngine(context: context, api: api, monitor: monitor)
        self.api = api
        self.syncEngine = syncEngine
        self.repository = TodoRepository(context: context, syncEngine: syncEngine)
        syncEngine.onChange = { [weak self] in
            self?.reload()
        }
        reload()
        // Send anything left from the last session
        syncEngine.syncNext()
    }

    // MARK: - Actions

    func add() {
        let title = newTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        repository.add(title: title)
        newTitle = ""
        reload()
    }

    func toggle(_ todo: Todo) {
        repository.toggle(todo)
        reload()
    }

    func delete(at offsets: IndexSet) {
        let items = todos
        for index in offsets {
            repository.delete(items[index])
        }
        reload()
    }

    // MARK: - Refresh from local store

    func reload() {
        todos = repository.fetchAll()
        pendingCount = repository.pendingCount()
    }
}
