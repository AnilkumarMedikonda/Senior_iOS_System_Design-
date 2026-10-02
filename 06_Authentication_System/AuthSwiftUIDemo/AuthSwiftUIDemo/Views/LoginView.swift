//
//  LoginView.swift
//  AuthSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import SwiftUI

struct LoginView: View {
    let session: SessionManager
    @State private var viewModel: LoginViewModel

    init(session: SessionManager) {
        self.session = session
        _viewModel = State(initialValue: LoginViewModel(session: session))
    }

    var body: some View {
        NavigationStack {
            Form {
                // Forced logout reason
                if let message = session.expiryMessage {
                    Section {
                        Label(message, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                }
                Section("Account") {
                    TextField("Username", text: $viewModel.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Password", text: $viewModel.password)
                }
                if let error = viewModel.errorMessage {
                    Text(error).foregroundStyle(.red)
                }
                Section {
                    Button {
                        viewModel.login()
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Log In")
                        }
                    }
                    .disabled(!viewModel.canSubmit)
                }
            }
            .navigationTitle("Login")
        }
    }
}
