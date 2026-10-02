//
//  RootView.swift
//  AuthSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import SwiftUI

struct RootView: View {
    let session: SessionManager

    var body: some View {
        // Replace the root, never present Login on top
        switch session.state {
        case .checking:
            VStack(spacing: 12) {
                Image(systemName: "lock.shield.fill").font(.system(size: 60))
                ProgressView("Checking session…")
            }
        case .loggedOut:
            LoginView(session: session)
        case .loggedIn:
            HomeView(session: session)
        }
    }
}
