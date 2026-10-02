//
//  HomeView.swift
//  AuthSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import SwiftUI

struct HomeView: View {
    let session: SessionManager
    @State private var viewModel: HomeViewModel

    init(session: SessionManager) {
        self.session = session
        _viewModel = State(initialValue: HomeViewModel(session: session))
    }

    var body: some View {
        NavigationStack {
            List {
                Section("User") {
                    if let user = session.user {
                        Text("Hi, \(user.firstName) (@\(user.username))")
                    } else {
                        Text("Offline: cached session")
                    }
                }
                Section("Test") {
                    Button("Load Profile") { viewModel.loadProfile() }
                    Button("Expire Access Token") { viewModel.expireToken() }
                    Button("Fire 5 Parallel Requests") { viewModel.fireParallelRequests() }
                    Button("Log Out", role: .destructive) { viewModel.logout() }
                }
                Section("Log") {
                    ForEach(Array(viewModel.log.enumerated()), id: \.offset) { item in
                        Text(item.element).font(.footnote.monospaced())
                    }
                }
            }
            .navigationTitle("Home")
        }
    }
}
