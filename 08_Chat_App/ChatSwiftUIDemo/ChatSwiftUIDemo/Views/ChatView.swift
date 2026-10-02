//
//  ChatView.swift
//  ChatSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import SwiftUI
import SwiftData

struct ChatView: View {
    @State private var viewModel: ChatViewModel
    @Query(sort: \ChatMessage.createdAt) private var stored: [ChatMessage]
    @Environment(\.scenePhase) private var scenePhase

    init(viewModel: ChatViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    // Confirmed by server seq, pending (no seq) at the bottom
    private var messages: [ChatMessage] {
        return stored.sorted { a, b in
            switch (a.seq, b.seq) {
            case let (x?, y?):
                return x < y
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                return a.createdAt < b.createdAt
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                messageList
                if viewModel.isOtherTyping {
                    Text("Bot is typing…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }
                inputBar
            }
            .navigationTitle("Bot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) { header }
                ToolbarItem(placement: .topBarTrailing) { debugMenu }
            }
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                viewModel.appBecameActive()
            } else if phase == .background {
                viewModel.appWentToBackground()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 0) {
            Text("Bot").font(.headline)
            Text(viewModel.connectionText)
                .font(.caption2)
                .foregroundStyle(viewModel.isOnline ? .green : .orange)
        }
    }

    // MARK: - Messages

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(messages) { message in
                        bubble(message).id(message.clientID)
                    }
                }
                .padding()
            }
            .onChange(of: stored.count) { _, _ in
                if let last = messages.last {
                    if !last.isMine {
                        viewModel.messageArrived()
                    }
                    withAnimation { proxy.scrollTo(last.clientID, anchor: .bottom) }
                }
            }
        }
    }

    private func bubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.isMine { Spacer() }
            VStack(alignment: message.isMine ? .trailing : .leading, spacing: 2) {
                Text(message.text)
                    .padding(10)
                    .background(message.isMine ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundStyle(message.isMine ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                if message.isMine {
                    statusView(message)
                }
            }
            if !message.isMine { Spacer() }
        }
    }

    @ViewBuilder
    private func statusView(_ message: ChatMessage) -> some View {
        switch message.status {
        case .sending:
            Image(systemName: "clock").font(.caption2).foregroundStyle(.secondary)
        case .sent:
            Text("✓").font(.caption2).foregroundStyle(.secondary)
        case .delivered:
            Text("✓✓").font(.caption2).foregroundStyle(.secondary)
        case .read:
            Text("✓✓").font(.caption2).foregroundStyle(.blue)
        case .failed:
            Button {
                viewModel.retry(message)
            } label: {
                Label("Not sent · Tap to retry", systemImage: "exclamationmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Input

    private var inputBar: some View {
        HStack {
            TextField("Message", text: $viewModel.draft)
                .textFieldStyle(.roundedBorder)
                .onSubmit { viewModel.send() }
            Button {
                viewModel.send()
            } label: {
                Image(systemName: "paperplane.fill")
            }
            .disabled(viewModel.draft.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding()
    }

    // MARK: - Debug

    private var debugMenu: some View {
        Menu {
            Button("Drop connection") { viewModel.dropConnection() }
            Button("Lose next ack") { viewModel.loseNextAck() }
            Button(viewModel.isNetworkUp ? "Go offline" : "Go online") { viewModel.toggleNetwork() }
        } label: {
            Image(systemName: "ladybug")
        }
    }
}
