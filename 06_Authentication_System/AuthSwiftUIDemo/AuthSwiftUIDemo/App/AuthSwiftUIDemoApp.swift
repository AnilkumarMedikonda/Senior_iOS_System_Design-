//
//  AuthSwiftUIDemoApp.swift
//  AuthSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import SwiftUI

@main
struct AuthSwiftUIDemoApp: App {
    @State private var session = SessionManager()

    var body: some Scene {
        WindowGroup {
            RootView(session: session)
                .onAppear {
                    session.restoreSession()
                }
        }
    }
}
