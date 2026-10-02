//
//  Todo.swift
//  OfflineSyncSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation
import SwiftData

enum SyncStatus: String, Codable {
    case synced
    case pending
    case failed
}

@Model
final class Todo {
    @Attribute(.unique) var id: UUID
    var title: String
    var isDone: Bool
    var updatedAt: Date
    var syncStatusRaw: String

    var syncStatus: SyncStatus {
        get {
            if let status = SyncStatus(rawValue: syncStatusRaw) {
                return status
            } else {
                return .pending
            }
        }
        set {
            syncStatusRaw = newValue.rawValue
        }
    }

    init(title: String) {
        self.id = UUID()
        self.title = title
        self.isDone = false
        self.updatedAt = Date()
        self.syncStatusRaw = SyncStatus.pending.rawValue
    }
}
