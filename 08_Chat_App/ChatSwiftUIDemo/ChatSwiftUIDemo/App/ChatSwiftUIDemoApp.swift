//
//  ChatSwiftUIDemoApp.swift
//  ChatSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import SwiftUI
import SwiftData

@main
struct ChatSwiftUIDemoApp: App {
    let container: ModelContainer
    @State private var viewModel: ChatViewModel

    init() {
        let container: ModelContainer
        do {
            container = try ModelContainer(for: ChatMessage.self)
        } catch {
            fatalError("SwiftData setup failed: \(error)")
        }
        self.container = container
        // Wire the chat stack once
        let server = FakeChatServer()
        let socket = SocketConnection(server: server)
        let store = MessageStore(context: container.mainContext)
        let client = ChatClient(store: store, socket: socket, server: server)
        _viewModel = State(initialValue: ChatViewModel(client: client))
    }

    var body: some Scene {
        WindowGroup {
            ChatView(viewModel: viewModel)
        }
        .modelContainer(container)
    }
}
