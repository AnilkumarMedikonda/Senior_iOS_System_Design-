//
//  MessageStore.swift
//  ChatSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//


import Foundation
import SwiftData

final class MessageStore {
    private let context: ModelContext
    private let conversationID = ChatConstants.conversationID

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Outgoing (optimistic insert)

    @discardableResult
    func insertOutgoing(_ text: String) -> ChatMessage {
        let message = ChatMessage(clientID: UUID(), conversationID: conversationID, senderID: ChatConstants.me, text: text, status: .sending)
        context.insert(message)
        save()
        print("STORE: insert 🕓 \"\(text)\"")
        return message
    }

    // MARK: - Outbox = messages still .sending (FIFO)

    func pendingOutbox() -> [ChatMessage] {
        let sending = MessageStatus.sending.rawValue
        let descriptor = FetchDescriptor<ChatMessage>(
            predicate: #Predicate { $0.statusRaw == sending },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        if let result = try? context.fetch(descriptor) {
            return result
        } else {
            return []
        }
    }

    // MARK: - Ack → sent ✓

    func markSent(clientID: UUID, serverID: String, seq: Int) {
        guard let message = find(clientID: clientID) else { return }
        message.serverID = serverID
        message.seq = seq
        advance(message, to: .sent)
        save()
        print("STORE: ✓ seq \(seq) \"\(message.text)\"")
    }

    // MARK: - Incoming (upsert, never duplicate)

    func upsert(_ wire: WireMessage) {
        // 1. My own message echoed back (catch-up) → fill seq
        if let mine = find(clientID: wire.clientID) {
            if mine.seq == nil {
                mine.serverID = wire.serverID
                mine.seq = wire.seq
                advance(mine, to: .sent)
                save()
            }
            return
        }
        // 2. Already stored by serverID → skip
        if find(serverID: wire.serverID) != nil {
            return
        }
        // 3. New → insert
        let message = ChatMessage(clientID: wire.clientID, conversationID: wire.conversationID, senderID: wire.senderID, text: wire.text, status: .sent)
        message.serverID = wire.serverID
        message.seq = wire.seq
        context.insert(message)
        save()
        print("STORE: new seq \(wire.seq) \"\(wire.text)\"")
    }

    // MARK: - Receipts (watermarks, forward only)

    func applyReceipt(deliveredSeq: Int, readSeq: Int) {
        let me = ChatConstants.me
        let descriptor = FetchDescriptor<ChatMessage>(predicate: #Predicate { $0.senderID == me })
        guard let mine = try? context.fetch(descriptor) else { return }
        for message in mine {
            guard let seq = message.seq else { continue }
            if seq <= readSeq {
                advance(message, to: .read)
            } else if seq <= deliveredSeq {
                advance(message, to: .delivered)
            }
        }
        save()
    }

    // MARK: - Failed / retry

    func markFailed(clientID: UUID) {
        guard let message = find(clientID: clientID) else { return }
        message.status = .failed
        save()
        print("STORE: ❗ failed \"\(message.text)\"")
    }

    func markForRetry(clientID: UUID) {
        guard let message = find(clientID: clientID) else { return }
        message.status = .sending
        save()
    }

    // MARK: - Sync helpers

    func lastSeq() -> Int {
        var descriptor = FetchDescriptor<ChatMessage>(sortBy: [SortDescriptor(\.seq, order: .reverse)])
        descriptor.fetchLimit = 1
        if let newest = try? context.fetch(descriptor).first, let seq = newest.seq {
            return seq
        } else {
            return 0
        }
    }

    func newestIncomingSeq() -> Int {
        let bot = ChatConstants.bot
        var descriptor = FetchDescriptor<ChatMessage>(
            predicate: #Predicate { $0.senderID == bot },
            sortBy: [SortDescriptor(\.seq, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        if let newest = try? context.fetch(descriptor).first, let seq = newest.seq {
            return seq
        } else {
            return 0
        }
    }

    // MARK: - Private

    private func advance(_ message: ChatMessage, to status: MessageStatus) {
        // Only forward: sent → delivered → read (failed can move up)
        if message.status == .failed || status > message.status {
            message.status = status
        }
    }

    private func find(clientID: UUID) -> ChatMessage? {
        let descriptor = FetchDescriptor<ChatMessage>(predicate: #Predicate { $0.clientID == clientID })
        if let result = try? context.fetch(descriptor) {
            return result.first
        } else {
            return nil
        }
    }

    private func find(serverID: String) -> ChatMessage? {
        let id: String? = serverID
        let descriptor = FetchDescriptor<ChatMessage>(predicate: #Predicate { $0.serverID == id })
        if let result = try? context.fetch(descriptor) {
            return result.first
        } else {
            return nil
        }
    }

    private func save() {
        try? context.save()
    }
}
