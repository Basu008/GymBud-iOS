//
//  SignUpViewModel.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import Combine
import Foundation

@MainActor
final class SignUpViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var didSignUp = false
    @Published private(set) var successMessage: String?
    @Published var errorMessage: String?

    private let authService: any AuthServiceProtocol

    init() {
        self.authService = AuthService()
    }

    init(authService: any AuthServiceProtocol) {
        self.authService = authService
    }

    func signUp(username: String, password: String, email: String) async {
        guard !isLoading else { return }

        isLoading = true
        didSignUp = false
        successMessage = nil
        errorMessage = nil

        do {
            didSignUp = try await authService.signUp(
                username: username,
                password: password,
                email: email
            )

            if didSignUp {
                successMessage = AppStrings.SignUp.successMessage
                return
            } else {
                errorMessage = AppStrings.SignUp.genericErrorMessage
            }
        } catch {
            errorMessage = AppStrings.SignUp.genericErrorMessage
        }

        isLoading = false
    }
}
