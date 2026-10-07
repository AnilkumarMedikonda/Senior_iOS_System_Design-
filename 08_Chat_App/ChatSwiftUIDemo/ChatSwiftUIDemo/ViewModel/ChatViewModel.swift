//
//  ChatViewModel.swift
//  ChatSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation
import Observation

@Observable
final class ChatViewModel {
    var draft = "" {
        didSet {
            if !draft.isEmpty {
                client.userIsTyping()
            }
        }
    }
    private(set) var connection: ConnectionState = .disconnected
    private(set) var isOtherTyping = false
    private(set) var isNetworkUp = true
    private let client: ChatClient
    private var typingHideWork: DispatchWorkItem?

    init(client: ChatClient) {
        self.client = client
        client.onConnectionChange = { [weak self] state in
            self?.connection = state
        }
        client.onOtherTyping = { [weak self] in
            self?.showTyping()
        }
    }

    // MARK: - Connection label

    var connectionText: String {
        switch connection {
        case .connected:
            return "Online"
        case .connecting:
            return "Connecting…"
        case .disconnected:
            return "Offline"
        case .reconnecting(let seconds):
            return "Reconnecting in \(seconds)s…"
        }
    }

    var isOnline: Bool {
        return connection == .connected
    }

    // MARK: - Screen + app lifecycle

    func onAppear() {
        client.start()
        client.setChatVisible(true)
    }

    func onDisappear() {
        client.setChatVisible(false)
    }

    func appBecameActive() {
        client.start()
        client.setChatVisible(true)
    }

    func appWentToBackground() {
        client.setChatVisible(false)
        client.stop()                   // push takes over in background
    }

    // MARK: - Actions

    func send() {
        client.send(draft)
        draft = ""
    }

    func retry(_ message: ChatMessage) {
        client.retry(message)
    }

    // MARK: - Typing indicator (auto-hide)

    private func showTyping() {
        isOtherTyping = true
        typingHideWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.isOtherTyping = false
        }
        typingHideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: work)
    }

    func messageArrived() {
        // Reply replaces "typing…"
        isOtherTyping = false
    }

    // MARK: - Debug

    func dropConnection() {
        client.debugDropConnection()
    }

    func loseNextAck() {
        client.debugLoseNextAck()
    }

    func toggleNetwork() {
        isNetworkUp.toggle()
        client.debugSetNetwork(up: isNetworkUp)
    }
}
