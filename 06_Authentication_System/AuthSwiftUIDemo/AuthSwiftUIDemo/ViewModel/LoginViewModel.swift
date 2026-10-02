//
//  LoginViewModel.swift
//  AuthSwiftUIDemo
//
//  Created by Medikonda Anil kumar on 02/10/26.
//

import Foundation
import Observation

@Observable
final class LoginViewModel {
    var username = "emilys"
    var password = "emilyspass"
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private let session: SessionManager

    init(session: SessionManager) {
        self.session = session
    }

    var canSubmit: Bool {
        return !username.isEmpty && !password.isEmpty && !isLoading
    }

    func login() {
        guard canSubmit else { return }
        isLoading = true
        errorMessage = nil
        session.login(username: username, password: password) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            switch result {
            case .success:
                break                                   // root switches to Home
            case .failure(.network):
                self.errorMessage = "You're offline"
            case .failure:
                self.errorMessage = "Wrong username or password"
            }
        }
    }
}
