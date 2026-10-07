//
//  SocketConnection.swift
//  ChatSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case reconnecting(seconds: Int)
}

final class SocketConnection {
    private(set) var state: ConnectionState = .disconnected
    var onStateChange: ((ConnectionState) -> Void)?
    var onEvent: ((ServerEvent) -> Void)?

    private let server: FakeChatServer
    private var attempt = 0
    private var reconnectScheduled = false
    private var pingTimer: Timer?
    private let pingInterval: TimeInterval = 5      // real apps: ~25s

    init(server: FakeChatServer) {
        self.server = server
        server.onEvent = { [weak self] event in
            self?.onEvent?(event)
        }
    }

    var isConnected: Bool {
        return state == .connected
    }

    // MARK: - Connect (handshake)

    func connect() {
        guard state != .connected, state != .connecting else { return }
        setState(.connecting)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard self.server.isNetworkUp else {
                print("SOCKET: handshake failed")
                self.scheduleReconnect()
                return
            }
            self.attempt = 0
            self.server.isClientConnected = true
            self.setState(.connected)
            self.startPing()
        }
    }

    // MARK: - Send (false = not sent, caller keeps it in outbox)

    @discardableResult
    func send(_ event: ClientEvent) -> Bool {
        guard isConnected, server.isNetworkUp else { return false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.server.receive(event)
        }
        return true
    }

    // MARK: - Disconnect (app → background)

    func disconnect() {
        stopPing()
        server.isClientConnected = false
        setState(.disconnected)
    }

    // MARK: - Drop + backoff reconnect

    func simulateDrop() {
        print("SOCKET: connection dropped")
        stopPing()
        server.isClientConnected = false
        scheduleReconnect()
    }

    private func scheduleReconnect() {
        guard !reconnectScheduled else { return }
        reconnectScheduled = true
        attempt += 1
        let base = min(pow(2.0, Double(attempt)), 30)
        let delay = base + Double.random(in: 0...1)          // jitter
        setState(.reconnecting(seconds: Int(delay.rounded())))
        print("SOCKET: reconnect attempt \(attempt) in \(String(format: "%.1f", delay))s")
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.reconnectScheduled = false
            self.setState(.disconnected)
            self.connect()
        }
    }

    // MARK: - Network monitor (NWPathMonitor in a real app)

    func networkDidChange(isUp: Bool) {
        server.isNetworkUp = isUp
        if isUp {
            print("SOCKET: network back → reconnect now")
            attempt = 0
            if !isConnected && !reconnectScheduled {
                connect()
            }
        }
    }

    // MARK: - Ping (detects dead connections)

    private func startPing() {
        stopPing()
        pingTimer = Timer.scheduledTimer(withTimeInterval: pingInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if !self.server.isNetworkUp {
                print("SOCKET: ping failed → connection dead")
                self.simulateDrop()
            }
        }
    }

    private func stopPing() {
        pingTimer?.invalidate()
        pingTimer = nil
    }

    private func setState(_ newState: ConnectionState) {
        state = newState
        onStateChange?(newState)
    }
}
