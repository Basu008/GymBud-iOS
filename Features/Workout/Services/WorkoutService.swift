//
//  WorkoutService.swift
//  GymBud
//
//  Created by Codex on 03/05/26.
//

import Foundation

nonisolated protocol WorkoutServiceProtocol: Sendable {
    nonisolated func storedAccessToken() -> String?
    nonisolated func latestWorkout(routineID: String, accessToken: String) async throws -> WorkoutLog?
    nonisolated func completeWorkout(_ request: CompleteWorkoutRequest, accessToken: String) async throws -> WorkoutLog
    nonisolated func analytics(accessToken: String) async throws -> WorkoutAnalyticsPayload
    nonisolated func userWorkouts(userID: String, page: Int, accessToken: String) async throws -> [WorkoutLog]
    nonisolated func deleteWorkout(id: String, accessToken: String) async throws -> String
}

nonisolated final class WorkoutService: Sendable {
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

    nonisolated func latestWorkout(routineID: String, accessToken: String) async throws -> WorkoutLog? {
        do {
            let response = try await apiClient.request(
                WorkoutEndpoint.latestWorkout(routineID: routineID, accessToken: accessToken),
                responseType: APIResponse<LatestWorkoutPayload>.self
            )

            return try response.requirePayload().workout
        } catch APIError.requestFailed(let statusCode, _, _) where statusCode == 404 {
            return nil
        }
    }

    nonisolated func completeWorkout(_ request: CompleteWorkoutRequest, accessToken: String) async throws -> WorkoutLog {
        let response = try await apiClient.request(
            WorkoutEndpoint.completeWorkout(request, accessToken: accessToken),
            responseType: APIResponse<CompleteWorkoutPayload>.self
        )

        return try response.requirePayload().workout
    }

    nonisolated func analytics(accessToken: String) async throws -> WorkoutAnalyticsPayload {
        let response = try await apiClient.request(
            WorkoutEndpoint.analytics(accessToken: accessToken),
            responseType: APIResponse<WorkoutAnalyticsPayload>.self
        )

        return try response.requirePayload()
    }

    nonisolated func userWorkouts(userID: String, page: Int, accessToken: String) async throws -> [WorkoutLog] {
        let response = try await apiClient.request(
            WorkoutEndpoint.userWorkouts(userID: userID, page: page, accessToken: accessToken),
            responseType: APIResponse<WorkoutListPayload>.self
        )

        return try response.requirePayload().workouts
    }

    nonisolated func deleteWorkout(id: String, accessToken: String) async throws -> String {
        let response = try await apiClient.request(
            WorkoutEndpoint.deleteWorkout(id: id, accessToken: accessToken),
            responseType: APIResponse<DeleteWorkoutPayload>.self
        )

        return try response.requirePayload().deletedID
    }
}

nonisolated extension WorkoutService: WorkoutServiceProtocol {}
