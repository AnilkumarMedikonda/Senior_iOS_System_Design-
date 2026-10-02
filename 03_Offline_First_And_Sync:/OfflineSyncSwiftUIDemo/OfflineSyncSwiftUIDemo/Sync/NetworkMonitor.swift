//
//  NetworkMonitor.swift
//  OfflineSyncSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation
import Network

final class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private(set) var isOnline = true
    var onStatusChange: ((Bool) -> Void)?

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let online = (path.status == .satisfied)
            if online != self.isOnline {
                self.isOnline = online
                print("NETWORK: \(online ? "online" : "offline")")
                self.onStatusChange?(online)
            }
        }
        // Callbacks arrive on main → safe to touch UI and SwiftData
        monitor.start(queue: .main)
    }

    func stop() {
        monitor.cancel()
    }
}
