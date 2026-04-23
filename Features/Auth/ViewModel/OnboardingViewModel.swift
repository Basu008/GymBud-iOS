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

    init(
        content: OnboardingContent = .mock,
        authService: AuthServiceProtocol = AuthService()
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
