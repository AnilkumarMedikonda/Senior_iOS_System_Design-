//
//  DeepLinkSwiftUIDemoApp.swift
//  DeepLinkSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import SwiftUI

@main
struct DeepLinkSwiftUIDemoApp: App {
    @State private var router: AppRouter
    @State private var handler: DeepLinkHandler

    init() {
        let router = AppRouter()
        _router = State(initialValue: router)
        _handler = State(initialValue: DeepLinkHandler(router: router))
    }

    var body: some Scene {
        WindowGroup {
            RootView(router: router, handler: handler)
                .environment(router)
                .environment(handler)
                .onOpenURL { url in
                    // Universal Links + custom scheme, cold and warm
                    handler.open(url)
                }
                .onAppear {
                    // Simulated splash: restore session, load config
                    handler.startLaunch(restoredLogin: false)
                }
        }
    }
}
