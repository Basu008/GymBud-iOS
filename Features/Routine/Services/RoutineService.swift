//
//  RoutineService.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import Foundation

nonisolated protocol RoutineServiceProtocol: Sendable {
    nonisolated func storedAccessToken() -> String?
    nonisolated func routines(page: Int, accessToken: String) async throws -> [Routine]
    nonisolated func createRoutine(_ request: CreateRoutineRequest, accessToken: String) async throws -> Routine
    nonisolated func updateRoutine(id: String, request: CreateRoutineRequest, accessToken: String) async throws -> Routine
    nonisolated func deleteRoutine(id: String, accessToken: String) async throws -> String
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

    nonisolated func routines(page: Int, accessToken: String) async throws -> [Routine] {
        let response = try await apiClient.request(
            RoutineEndpoint.routines(page: page, accessToken: accessToken),
            responseType: APIResponse<RoutinesPayload>.self
        )

        return try response.requirePayload().routines
    }

    nonisolated func createRoutine(_ request: CreateRoutineRequest, accessToken: String) async throws -> Routine {
        let response = try await apiClient.request(
            RoutineEndpoint.createRoutine(request, accessToken: accessToken),
            responseType: APIResponse<CreateRoutinePayload>.self
        )

        return try response.requirePayload().routine
    }

    nonisolated func updateRoutine(id: String, request: CreateRoutineRequest, accessToken: String) async throws -> Routine {
        let response = try await apiClient.request(
            RoutineEndpoint.updateRoutine(id: id, request, accessToken: accessToken),
            responseType: APIResponse<UpdateRoutinePayload>.self
        )

        return try response.requirePayload().routine
    }

    nonisolated func deleteRoutine(id: String, accessToken: String) async throws -> String {
        let response = try await apiClient.request(
            RoutineEndpoint.deleteRoutine(id: id, accessToken: accessToken),
            responseType: APIResponse<DeleteRoutinePayload>.self
        )

        return try response.requirePayload().deletedID
    }
}

nonisolated extension RoutineService: RoutineServiceProtocol {}
