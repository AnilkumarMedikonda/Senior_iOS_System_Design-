//
//  ChatModels.swift
//  ChatSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation
import SwiftData

// MARK: - Status (only moves forward)

enum MessageStatus: Int, Codable, Comparable {
    case sending = 0        // in outbox, waiting for ack
    case sent = 1           // server ack ✓
    case delivered = 2      // recipient device ✓✓
    case read = 3           // recipient opened ✓✓ blue
    case failed = -1        // gave up → tap to retry

    static func < (lhs: MessageStatus, rhs: MessageStatus) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Message (local DB = source of truth)

@Model
final class ChatMessage {
    @Attribute(.unique) var clientID: UUID      // made on device → idempotency key
    var serverID: String?                       // set after ack
    var seq: Int?                               // server order, nil while sending
    var conversationID: String
    var senderID: String
    var text: String
    var createdAt: Date
    var statusRaw: Int

    var status: MessageStatus {
        get {
            if let value = MessageStatus(rawValue: statusRaw) {
                return value
            } else {
                return .sending
            }
        }
        set {
            statusRaw = newValue.rawValue
        }
    }

    var isMine: Bool {
        return senderID == ChatConstants.me
    }

    init(clientID: UUID, conversationID: String, senderID: String, text: String, status: MessageStatus) {
        self.clientID = clientID
        self.conversationID = conversationID
        self.senderID = senderID
        self.text = text
        self.createdAt = Date()
        self.statusRaw = status.rawValue
    }
}

// MARK: - Wire events (what a WebSocket would carry)

struct WireMessage {
    let clientID: UUID
    let serverID: String
    let seq: Int
    let conversationID: String
    let senderID: String
    let text: String
}

enum ClientEvent {
    case send(clientID: UUID, conversationID: String, text: String)
    case receipt(conversationID: String, deliveredSeq: Int, readSeq: Int)
    case typing(conversationID: String)
}

enum ServerEvent {
    case ack(clientID: UUID, serverID: String, seq: Int)
    case newMessage(WireMessage)
    case receipt(conversationID: String, deliveredSeq: Int, readSeq: Int)
    case typing(conversationID: String, userID: String)
}

// MARK: - Constants

enum ChatConstants {
    static let me = "me"
    static let bot = "bot"
    static let conversationID = "c1"
}
