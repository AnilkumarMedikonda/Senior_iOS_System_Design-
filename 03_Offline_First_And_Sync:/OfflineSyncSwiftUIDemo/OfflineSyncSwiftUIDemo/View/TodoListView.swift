//
//  TodoListView.swift
//  OfflineSyncSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import SwiftUI
import SwiftData

struct TodoListView: View {
    @State private var viewModel: TodoListViewModel

    init(context: ModelContext) {
        _viewModel = State(initialValue: TodoListViewModel(context: context))
    }

    var body: some View {
        NavigationStack {
            List {
                // 1. Sync status
                Section {
                    Toggle("Offline Mode", isOn: $viewModel.isOfflineMode)
                    HStack {
                        Text("Pending changes")
                        Spacer()
                        Text("\(viewModel.pendingCount)")
                            .foregroundStyle(viewModel.pendingCount > 0 ? .orange : .green)
                    }
                }
                // 2. Add
                Section {
                    HStack {
                        TextField("New todo", text: $viewModel.newTitle)
                            .onSubmit { viewModel.add() }
                        Button("Add") { viewModel.add() }
                    }
                }
                // 3. Todos
                Section("Todos") {
                    ForEach(viewModel.todos) { todo in
                        row(todo)
                    }
                    .onDelete { offsets in
                        viewModel.delete(at: offsets)
                    }
                }
            }
            .navigationTitle("Offline Todos")
        }
    }

    private func row(_ todo: Todo) -> some View {
        HStack {
            Button {
                viewModel.toggle(todo)
            } label: {
                Image(systemName: todo.isDone ? "checkmark.circle.fill" : "circle")
            }
            .buttonStyle(.plain)
            Text(todo.title)
                .strikethrough(todo.isDone)
            Spacer()
            statusIcon(todo.syncStatus)
        }
    }

    @ViewBuilder
    private func statusIcon(_ status: SyncStatus) -> some View {
        switch status {
        case .synced:
            Image(systemName: "checkmark.icloud").foregroundStyle(.green)
        case .pending:
            Image(systemName: "clock").foregroundStyle(.orange)
        case .failed:
            Image(systemName: "exclamationmark.icloud").foregroundStyle(.red)
        }
    }
}
