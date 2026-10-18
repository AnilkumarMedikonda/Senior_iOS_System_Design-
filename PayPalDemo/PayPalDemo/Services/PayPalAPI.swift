//
//  PayPalAPI.swift
//  PayPalDemo
//
//  Created by Medikonda Anil kumar on 18/10/26.
//

import Foundation

// Server contract for PayPal orders
protocol PayPalAPIProtocol {
    func createOrder(amount: Decimal) async throws -> String
    func captureOrder(id: String) async throws -> Bool
}

// Calls our Node server
final class PayPalAPI: PayPalAPIProtocol {
    private let baseURL = URL(string: "http://localhost:3000")!

    private struct OrderResponse: Decodable {
        let id: String
        let status: String
    }

    // Create order → orderID
    func createOrder(amount: Decimal) async throws -> String {
        let order: OrderResponse = try await post("orders", body: ["amount": "\(amount)"])
        return order.id
    }

    // Capture after approval → true if paid
    func captureOrder(id: String) async throws -> Bool {
        let order: OrderResponse = try await post("orders/\(id)/capture", body: [:])
        return order.status == "COMPLETED"
    }

    // Shared POST + decode
    private func post<T: Decodable>(_ path: String, body: [String: String]) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode ?? 0 < 300 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
