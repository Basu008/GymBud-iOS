//
//  AuthService.swift
//  GymBud
//
//  Created by Basu Singh on 23/04/26.
//

import Foundation

nonisolated protocol AuthServiceProtocol: Sendable {
    nonisolated func startSignupFlow()
    nonisolated func startSignInFlow()
    nonisolated func signUp(username: String, password: String, email: String) async throws -> Bool
}

nonisolated final class AuthService: Sendable {
    private let apiClient: any APIClientProtocol

    nonisolated init() {
        self.apiClient = APIClient()
    }

    nonisolated init(apiClient: any APIClientProtocol) {
        self.apiClient = apiClient
    }

    nonisolated func startSignupFlow() {
        // Hook navigation or analytics later
    }

    nonisolated func startSignInFlow() {
        // Hook navigation or analytics later
    }

    nonisolated func signUp(username: String, password: String, email: String) async throws -> Bool {
        let request = SignUpRequest(
            username: username,
            password: password,
            email: email
        )
        let response = try await apiClient.request(
            AuthEndpoint.signUp(request),
            responseType: APIResponse<Bool>.self
        )

        return response.success && response.payload
    }
}

nonisolated extension AuthService: AuthServiceProtocol {}
