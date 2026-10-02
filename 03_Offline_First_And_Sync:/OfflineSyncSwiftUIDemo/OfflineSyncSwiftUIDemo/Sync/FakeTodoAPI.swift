//
//  FakeTodoAPI.swift
//  OfflineSyncSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation

struct MutationRequest {
    let id: UUID
    let type: MutationType
    let todoID: UUID
    let title: String
    let isDone: Bool
    let updatedAt: Date

    init(_ mutation: PendingMutation) {
        self.id = mutation.id
        self.type = mutation.type
        self.todoID = mutation.todoID
        self.title = mutation.title
        self.isDone = mutation.isDone
        self.updatedAt = mutation.updatedAt
    }
}

enum APIError: Error {
    case offline
    case server(statusCode: Int)
}

final class FakeTodoAPI {
    var isOfflineMode = false
    var failureRate = 0.2
    private var serverTodos: [UUID: MutationRequest] = [:]
    private var processedIDs: Set<UUID> = []

    func send(_ request: MutationRequest, completion: @escaping (Result<Void, APIError>) -> Void) {
        // Simulated network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            // 1. Offline
            if self.isOfflineMode {
                completion(.failure(.offline))
                return
            }
            // 2. Random server error
            if Double.random(in: 0...1) < self.failureRate {
                completion(.failure(.server(statusCode: 500)))
                return
            }
            // 3. Idempotency — duplicate request, already applied
            if self.processedIDs.contains(request.id) {
                completion(.success(()))
                return
            }
            // 4. Apply change
            switch request.type {
            case .create, .update:
                self.serverTodos[request.todoID] = request
            case .delete:
                self.serverTodos[request.todoID] = nil
            }
            self.processedIDs.insert(request.id)
            print("SERVER: \(request.type.rawValue) \(request.title) | total = \(self.serverTodos.count)")

            completion(.success(()))
        }
    }
}
