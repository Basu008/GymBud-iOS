//
//  LogInViewModel.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import Combine
import Foundation

@MainActor
final class LogInViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var didLogIn = false
    @Published private(set) var needsUserInfo = false
    @Published private(set) var accessToken: String?
    @Published var errorMessage: String?

    private let authService: any AuthServiceProtocol

    init() {
        self.authService = AuthService()
    }

    init(authService: any AuthServiceProtocol) {
        self.authService = authService
    }

    func logIn(username: String, password: String) async {
        guard !isLoading else { return }

        isLoading = true
        didLogIn = false
        needsUserInfo = false
        accessToken = nil
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let response = try await authService.logIn(
                username: username,
                password: password
            )

            CurrentUserStore.shared.update(user: response.user)
            accessToken = response.accessToken
            didLogIn = true
            needsUserInfo = response.user.needsUserInfo
        } catch {
            errorMessage = AppStrings.LogIn.genericErrorMessage
        }
    }
}
