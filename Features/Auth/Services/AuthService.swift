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
    nonisolated func logIn(username: String, password: String) async throws -> LogInResponse
    nonisolated func logOut(accessToken: String) async throws
    nonisolated func storedAccessToken() -> String?
}

nonisolated final class AuthService: Sendable {
    private let apiClient: any APIClientProtocol
    private let tokenStore: any AuthTokenStoreProtocol

    nonisolated init() {
        self.apiClient = APIClient()
        self.tokenStore = AuthTokenStore()
    }

    nonisolated init(
        apiClient: any APIClientProtocol,
        tokenStore: any AuthTokenStoreProtocol = AuthTokenStore()
    ) {
        self.apiClient = apiClient
        self.tokenStore = tokenStore
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

        return try response.requirePayload()
    }

    nonisolated func logIn(username: String, password: String) async throws -> LogInResponse {
        let request = LogInRequest(username: username, password: password)
        let response = try await apiClient.request(
            AuthEndpoint.logIn(request),
            responseType: APIResponse<LogInResponse>.self
        )

        let payload = try response.requirePayload()
        tokenStore.clearAccessToken()
        tokenStore.saveAccessToken(payload.accessToken)
        return payload
    }

    nonisolated func storedAccessToken() -> String? {
        tokenStore.accessToken
    }

    nonisolated func logOut(accessToken: String) async throws {
        _ = try? await apiClient.request(AuthEndpoint.logOut(accessToken: accessToken))
        tokenStore.clearAccessToken()
    }
}

nonisolated extension AuthService: AuthServiceProtocol {}

nonisolated enum AuthServiceError: Error, Sendable {
    case unsuccessfulResponse
}
