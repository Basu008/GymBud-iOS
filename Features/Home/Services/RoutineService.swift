//
//  RoutineService.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import Foundation

nonisolated protocol RoutineServiceProtocol: Sendable {
    nonisolated func storedAccessToken() -> String?
    nonisolated func routines(accessToken: String) async throws -> [Routine]
}

nonisolated final class RoutineService: Sendable {
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

    nonisolated func storedAccessToken() -> String? {
        tokenStore.accessToken
    }

    nonisolated func routines(accessToken: String) async throws -> [Routine] {
        let response = try await apiClient.request(
            RoutineEndpoint.routines(accessToken: accessToken),
            responseType: APIResponse<RoutinesPayload>.self
        )

        return try response.requirePayload().routines
    }
}

nonisolated extension RoutineService: RoutineServiceProtocol {}
