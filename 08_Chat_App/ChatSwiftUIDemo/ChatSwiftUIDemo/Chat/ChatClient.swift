//
//  ChatClient.swift
//  ChatSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation

final class ChatClient {
    var onConnectionChange: ((ConnectionState) -> Void)?
    var onOtherTyping: (() -> Void)?

    private let store: MessageStore
    private let socket: SocketConnection
    private let server: FakeChatServer
    private var inFlight: Set<UUID> = []
    private var attempts: [UUID: Int] = [:]
    private let ackTimeout: TimeInterval = 3        // real apps: ~10s
    private let maxAttempts = 3
    private var isChatVisible = false
    private var lastReadSent = 0
    private var lastTypingSent = Date.distantPast

    init(store: MessageStore, socket: SocketConnection, server: FakeChatServer) {
        self.store = store
        self.socket = socket
        self.server = server
        socket.onEvent = { [weak self] event in
            self?.handle(event)
        }
        socket.onStateChange = { [weak self] state in
            guard let self = self else { return }
            if state == .connected {
                self.catchUpAndFlush()
            } else {
                // Unacked sends will be resent after reconnect
                self.inFlight.removeAll()
            }
            self.onConnectionChange?(state)
        }
    }

    // MARK: - Lifecycle

    func start() {
        socket.connect()
    }

    func stop() {
        socket.disconnect()
    }

    // MARK: - Send

    func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.insertOutgoing(trimmed)
        flush()
    }

    func retry(_ message: ChatMessage) {
        attempts[message.clientID] = nil
        store.markForRetry(clientID: message.clientID)
        flush()
    }

    // MARK: - Outbox flush (FIFO, remove only on ack)

    private func flush() {
        guard socket.isConnected else { return }
        for message in store.pendingOutbox() where !inFlight.contains(message.clientID) {
            let sent = socket.send(.send(clientID: message.clientID, conversationID: message.conversationID, text: message.text))
            if !sent { break }
            inFlight.insert(message.clientID)
            print("CLIENT: sent \"\(message.text)\" (waiting for ack)")
            let id = message.clientID
            DispatchQueue.main.asyncAfter(deadline: .now() + ackTimeout) { [weak self] in
                self?.ackTimedOut(id)
            }
        }
    }

    private func ackTimedOut(_ clientID: UUID) {
        guard inFlight.contains(clientID) else { return }        // already acked
        inFlight.remove(clientID)
        var count = 1
        if let previous = attempts[clientID] {
            count = previous + 1
        }
        attempts[clientID] = count
        if count >= maxAttempts {
            store.markFailed(clientID: clientID)
            return
        }
        print("CLIENT: ack timeout → resend same clientID (attempt \(count + 1))")
        flush()
    }

    // MARK: - Server events

    private func handle(_ event: ServerEvent) {
        switch event {
        case .ack(let clientID, let serverID, let seq):
            inFlight.remove(clientID)
            attempts[clientID] = nil
            store.markSent(clientID: clientID, serverID: serverID, seq: seq)
        case .newMessage(let wire):
            // Gap detection: missing seq in between → catch up
            let last = store.lastSeq()
            if wire.seq > last + 1 {
                print("CLIENT: gap \(last) → \(wire.seq), catching up")
                catchUpAndFlush()
            }
            store.upsert(wire)
            sendReceipts()
        case .receipt(_, let deliveredSeq, let readSeq):
            store.applyReceipt(deliveredSeq: deliveredSeq, readSeq: readSeq)
        case .typing:
            onOtherTyping?()
        }
    }

    // MARK: - Catch-up after reconnect

    private func catchUpAndFlush() {
        server.fetchMessages(after: store.lastSeq()) { [weak self] result in
            guard let self = self else { return }
            if case .success(let response) = result {
                for wire in response.messages {
                    self.store.upsert(wire)
                }
                self.store.applyReceipt(deliveredSeq: response.deliveredSeq, readSeq: response.readSeq)
                self.sendReceipts()
            }
            self.flush()
        }
    }

    // MARK: - My receipts (watermarks)

    func setChatVisible(_ visible: Bool) {
        isChatVisible = visible
        if visible {
            sendReceipts()
        }
    }

    private func sendReceipts() {
        let delivered = store.newestIncomingSeq()
        if isChatVisible {
            lastReadSent = delivered
        }
        socket.send(.receipt(conversationID: ChatConstants.conversationID, deliveredSeq: delivered, readSeq: lastReadSent))
    }

    // MARK: - Typing (throttled, never queued)

    func userIsTyping() {
        guard Date().timeIntervalSince(lastTypingSent) > 3 else { return }
        lastTypingSent = Date()
        socket.send(.typing(conversationID: ChatConstants.conversationID))
    }

    // MARK: - Debug

    func debugDropConnection() {
        socket.simulateDrop()
    }

    func debugLoseNextAck() {
        server.dropNextAck = true
    }

    func debugSetNetwork(up: Bool) {
        socket.networkDidChange(isUp: up)
    }
}
