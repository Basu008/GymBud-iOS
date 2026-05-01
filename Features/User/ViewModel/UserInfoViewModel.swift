//
//  UserInfoViewModel.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import Combine
import Foundation

@MainActor
final class UserInfoViewModel: ObservableObject {
    @Published private(set) var isSaving = false
    @Published var errorMessage: String?

    private let userService: any UserServiceProtocol

    init() {
        self.userService = UserService()
    }

    init(userService: any UserServiceProtocol) {
        self.userService = userService
    }

    func saveUserInfo(
        displayName: String,
        gender: String,
        dateOfBirth: String,
        heightCM: Double,
        weightKG: Double,
        profileImageData: Data?
    ) async -> Bool {
        guard !isSaving else { return false }

        let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDisplayName.isEmpty else {
            errorMessage = AppStrings.UserInfo.requiredNameMessage
            return false
        }

        guard let accessToken = userService.storedAccessToken(),
              !accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            errorMessage = AppStrings.UserInfo.missingTokenMessage
            return false
        }

        isSaving = true
        errorMessage = nil

        defer {
            isSaving = false
        }

        do {
            let profileImageURL: String?
            if let profileImageData {
                profileImageURL = try await userService.uploadProfileImage(
                    profileImageData,
                    accessToken: accessToken
                )
            } else {
                profileImageURL = nil
            }

            try await userService.updateProfile(
                displayName: trimmedDisplayName,
                gender: gender,
                dateOfBirth: dateOfBirth,
                profileImageURL: profileImageURL,
                accessToken: accessToken
            )

            try await userService.updateBodyMetric(
                heightCM: heightCM,
                weightKG: weightKG,
                accessToken: accessToken
            )

            return true
        } catch {
            errorMessage = AppStrings.UserInfo.genericErrorMessage
            return false
        }
    }
}
