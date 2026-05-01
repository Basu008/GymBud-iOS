//
//  UserService.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import Foundation

nonisolated protocol UserServiceProtocol: Sendable {
    nonisolated func storedAccessToken() -> String?
    nonisolated func currentUser(accessToken: String) async throws -> AuthenticatedUser
    nonisolated func updateProfile(displayName: String, gender: String, dateOfBirth: String, profileImageURL: String?, accessToken: String) async throws
    nonisolated func updateBodyMetric(heightCM: Double, weightKG: Double, accessToken: String) async throws
    nonisolated func uploadProfileImage(_ imageData: Data, accessToken: String) async throws -> String
}

nonisolated final class UserService: Sendable {
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

    nonisolated func currentUser(accessToken: String) async throws -> AuthenticatedUser {
        let response = try await apiClient.request(
            UserEndpoint.currentUser(accessToken: accessToken),
            responseType: APIResponse<AuthenticatedUser>.self
        )

        return try response.requirePayload()
    }

    nonisolated func updateProfile(displayName: String, gender: String, dateOfBirth: String, profileImageURL: String?, accessToken: String) async throws {
        guard gender == "M" || gender == "F" else {
            throw UserServiceError.unsupportedGender
        }

        let request = UpdateProfileRequest(
            displayName: displayName,
            gender: gender,
            dateOfBirth: dateOfBirth,
            profileImageURL: profileImageURL
        )

        _ = try await apiClient.request(
            UserEndpoint.updateProfile(request, accessToken: accessToken)
        )
    }

    nonisolated func updateBodyMetric(heightCM: Double, weightKG: Double, accessToken: String) async throws {
        let request = BodyMetricRequest(
            heightCM: heightCM,
            weightKG: weightKG
        )

        _ = try await apiClient.request(
            UserEndpoint.updateBodyMetric(request, accessToken: accessToken)
        )
    }

    nonisolated func uploadProfileImage(_ imageData: Data, accessToken: String) async throws -> String {
        let response = try await apiClient.request(
            UserEndpoint.uploadProfileImage(imageData: imageData, accessToken: accessToken),
            responseType: APIResponse<UploadProfileImageResponse>.self
        )

        return try response.requirePayload().imageURL
    }
}

nonisolated extension UserService: UserServiceProtocol {}

nonisolated enum UserServiceError: Error, Sendable {
    case unsuccessfulResponse
    case unsupportedGender
}
