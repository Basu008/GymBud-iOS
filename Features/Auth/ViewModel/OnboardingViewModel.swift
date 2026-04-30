//
//  OnboardingViewModel.swift
//  GymBud
//
//  Created by Basu Singh on 23/04/26.
//

import Foundation
import Combine

final class OnboardingViewModel: ObservableObject {
    @Published var content: OnboardingContent

    private let authService: AuthServiceProtocol

    init() {
        self.content = .mock
        self.authService = AuthService()
    }

    init(
        content: OnboardingContent,
        authService: AuthServiceProtocol
    ) {
        self.content = content
        self.authService = authService
    }

    func didTapGetStarted() {
        authService.startSignupFlow()
    }

    func didTapSignIn() {
        authService.startSignInFlow()
    }
}
