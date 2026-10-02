//
//  OfflineSyncSwiftUIDemoApp.swift
//  OfflineSyncSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import SwiftUI
import SwiftData

@main
struct OfflineSyncSwiftUIDemoApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Todo.self, PendingMutation.self)
        } catch {
            fatalError("SwiftData setup failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            TodoListView(context: container.mainContext)
        }
        .modelContainer(container)
    }
}
