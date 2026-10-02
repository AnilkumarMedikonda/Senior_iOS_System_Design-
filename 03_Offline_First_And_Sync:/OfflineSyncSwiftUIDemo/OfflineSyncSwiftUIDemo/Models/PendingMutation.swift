//
//  PendingMutation.swift
//  OfflineSyncSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation
import SwiftData

enum MutationType: String, Codable {
    case create
    case update
    case delete
}

@Model
final class PendingMutation {
    @Attribute(.unique) var id: UUID
    var typeRaw: String
    var todoID: UUID
    var title: String
    var isDone: Bool
    var updatedAt: Date
    var createdAt: Date
    var attempts: Int

    var type: MutationType {
        get {
            if let value = MutationType(rawValue: typeRaw) {
                return value
            } else {
                return .update
            }
        }
        set {
            typeRaw = newValue.rawValue
        }
    }

    init(type: MutationType, todo: Todo) {
        self.id = UUID()
        self.typeRaw = type.rawValue
        self.todoID = todo.id
        self.title = todo.title
        self.isDone = todo.isDone
        self.updatedAt = todo.updatedAt
        self.createdAt = Date()
        self.attempts = 0
    }
}
