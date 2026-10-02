//
//  DeepLinkHandler.swift
//  DeepLinkSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation
import Observation

@Observable
final class DeepLinkHandler {
    private(set) var isAppReady = false
    private let parser = DeepLinkParser()
    private let router: AppRouter
    private var pendingLink: DeepLink?

    init(router: AppRouter) {
        self.router = router
    }

    // MARK: - Every source enters here

    func open(_ url: URL) {
        print("HANDLER: open \(url.absoluteString) | ready = \(isAppReady)")
        // 1. Parse
        guard let link = parser.parse(url) else {
            router.handleUnknown(url)
            return
        }
        // 2. Warm start → navigate now
        if isAppReady {
            router.handle(link)
            return
        }
        // 3. Cold start → keep only the latest, wait
        pendingLink = link
        print("HANDLER: app not ready, pending = \(link)")
    }

    // MARK: - Called after splash / session restore

    func appDidBecomeReady() {
        isAppReady = true
        print("HANDLER: app ready")
        if let link = pendingLink {
            pendingLink = nil
            router.handle(link)
        }
    }

    // MARK: - Simulated launch work

    func startLaunch(restoredLogin: Bool) {
        // Splash: restore session, load config, build root UI
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.router.isLoggedIn = restoredLogin
            self.appDidBecomeReady()
        }
    }
}
