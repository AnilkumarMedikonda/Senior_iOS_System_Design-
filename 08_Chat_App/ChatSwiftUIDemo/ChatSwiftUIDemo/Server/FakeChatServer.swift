//
//  FakeChatServer.swift
//  ChatSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation

struct SyncResponse {
    let messages: [WireMessage]
    let deliveredSeq: Int       // bot's latest watermarks
    let readSeq: Int
}

final class FakeChatServer {
    // Debug switches
    var isNetworkUp = true
    var dropNextAck = false

    // Set by SocketConnection
    var isClientConnected = false
    var onEvent: ((ServerEvent) -> Void)?

    private var log: [WireMessage] = []              // server copy of the conversation
    private var byClientID: [UUID: WireMessage] = [:]   // idempotency store
    private var nextSeq = 1
    private var botDeliveredSeq = 0
    private var botReadSeq = 0

    // MARK: - WebSocket: client → server

    func receive(_ event: ClientEvent) {
        switch event {
        case .send(let clientID, let conversationID, let text):
            handleSend(clientID: clientID, conversationID: conversationID, text: text)
        case .receipt(_, let deliveredSeq, let readSeq):
            print("SERVER: client receipt delivered \(deliveredSeq) read \(readSeq)")
        case .typing:
            break
        }
    }

    private func handleSend(clientID: UUID, conversationID: String, text: String) {
        // 1. Duplicate (resend after lost ack) → same message, same ack
        if let existing = byClientID[clientID] {
            print("SERVER: duplicate clientID → re-ack seq \(existing.seq)")
            push(.ack(clientID: clientID, serverID: existing.serverID, seq: existing.seq), after: 0.3)
            return
        }
        // 2. Store with next seq
        let message = WireMessage(clientID: clientID, serverID: "m\(nextSeq)", seq: nextSeq, conversationID: conversationID, senderID: ChatConstants.me, text: text)
        nextSeq += 1
        log.append(message)
        byClientID[clientID] = message
        print("SERVER: stored \"\(text)\" seq \(message.seq)")
        // 3. Ack (unless debug says lose it)
        if dropNextAck {
            dropNextAck = false
            print("SERVER: ack LOST (debug)")
        } else {
            push(.ack(clientID: clientID, serverID: message.serverID, seq: message.seq), after: 0.3)
        }
        // 4. Bot: delivered → read → typing → reply
        simulateBot(for: message)
    }

    private func simulateBot(for message: WireMessage) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.botDeliveredSeq = max(self.botDeliveredSeq, message.seq)
            self.push(.receipt(conversationID: message.conversationID, deliveredSeq: self.botDeliveredSeq, readSeq: self.botReadSeq), after: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.botReadSeq = max(self.botReadSeq, message.seq)
            self.push(.receipt(conversationID: message.conversationID, deliveredSeq: self.botDeliveredSeq, readSeq: self.botReadSeq), after: 0)
            self.push(.typing(conversationID: message.conversationID, userID: ChatConstants.bot), after: 0.3)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            let reply = WireMessage(clientID: UUID(), serverID: "m\(self.nextSeq)", seq: self.nextSeq, conversationID: message.conversationID, senderID: ChatConstants.bot, text: "Echo: \(message.text)")
            self.nextSeq += 1
            self.log.append(reply)
            print("SERVER: bot reply seq \(reply.seq)")
            self.push(.newMessage(reply), after: 0)
        }
    }

    // MARK: - Server → client (lost if not connected)

    private func push(_ event: ServerEvent, after delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard self.isClientConnected, self.isNetworkUp else {
                print("SERVER: client offline → event dropped (catch-up will fix)")
                return
            }
            self.onEvent?(event)
        }
    }

    // MARK: - REST: GET /messages?after=seq (catch-up)

    func fetchMessages(after seq: Int, completion: @escaping (Result<SyncResponse, Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            guard self.isNetworkUp else {
                completion(.failure(URLError(.notConnectedToInternet)))
                return
            }
            var missed: [WireMessage] = []
            for message in self.log where message.seq > seq {
                missed.append(message)
            }
            print("SERVER: catch-up after \(seq) → \(missed.count) messages")
            completion(.success(SyncResponse(messages: missed, deliveredSeq: self.botDeliveredSeq, readSeq: self.botReadSeq)))
        }
    }
}
