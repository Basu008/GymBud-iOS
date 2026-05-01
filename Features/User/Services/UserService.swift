//
//  UserService.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import Combine
import Foundation
import UIKit

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

@MainActor
final class CurrentUserStore: ObservableObject {
    static let shared = CurrentUserStore()

    @Published private(set) var user: AuthenticatedUser?
    @Published private(set) var profileImage: UIImage?

    private var loadedProfileImageURL: URL?
    private var profileImageLoadTask: Task<Void, Never>?

    private init() {}

    func update(user: AuthenticatedUser) {
        self.user = user
        loadProfileImageIfNeeded(from: user.profileImageURL)
    }

    func setProfileImage(data: Data, profileImageURL: String?) {
        guard let profileImageURL,
              let url = URL(string: profileImageURL),
              let image = UIImage(data: data)
        else {
            return
        }

        profileImageLoadTask?.cancel()
        loadedProfileImageURL = url
        profileImage = image
        cacheProfileImageData(data, for: url)
    }

    func clear() {
        profileImageLoadTask?.cancel()
        profileImageLoadTask = nil
        user = nil
        profileImage = nil
        loadedProfileImageURL = nil
    }

    private func loadProfileImageIfNeeded(from profileImageURL: String?) {
        guard let profileImageURL,
              let url = URL(string: profileImageURL)
        else {
            profileImageLoadTask?.cancel()
            profileImageLoadTask = nil
            profileImage = nil
            loadedProfileImageURL = nil
            return
        }

        guard loadedProfileImageURL != url || profileImage == nil else {
            return
        }

        profileImageLoadTask?.cancel()
        loadedProfileImageURL = url

        if let cachedImage = cachedProfileImage(for: url) {
            profileImage = cachedImage
            return
        }

        profileImage = nil
        profileImageLoadTask = Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard !Task.isCancelled,
                      let image = UIImage(data: data)
                else {
                    return
                }

                cacheProfileImageData(data, for: url)
                self.profileImage = image
            } catch {
                guard !Task.isCancelled else { return }
                self.profileImage = nil
            }
        }
    }

    private func cachedProfileImage(for url: URL) -> UIImage? {
        guard let data = try? Data(contentsOf: cacheURL(for: url)) else {
            return nil
        }

        return UIImage(data: data)
    }

    private func cacheProfileImageData(_ data: Data, for url: URL) {
        let directory = cacheDirectory
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        try? data.write(to: cacheURL(for: url), options: [.atomic])
    }

    private func cacheURL(for url: URL) -> URL {
        let filename = Data(url.absoluteString.utf8)
            .base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "=", with: "")

        return cacheDirectory.appendingPathComponent("\(filename).jpg")
    }

    private var cacheDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ProfileImages", isDirectory: true)
    }
}
