//
//  LogInResponse.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import Foundation

nonisolated struct LogInResponse: Decodable, Sendable {
    let user: AuthenticatedUser
    let accessToken: String

    enum CodingKeys: String, CodingKey {
        case user
        case accessToken = "access_token"
    }
}

nonisolated struct AuthenticatedUser: Decodable, Sendable {
    let id: String
    let username: String
    let email: String
    let plan: String
    let gender: String?
    let dateOfBirth: String?
    let profileImageURL: String?
    let isPrivate: Bool
    let isActive: Bool
    let isVerified: Bool
    let createdAt: String
    let updatedAt: String
    let followersCount: Int
    let followingCount: Int

    var needsUserInfo: Bool {
        isBlank(gender) && isBlank(dateOfBirth) && isBlank(profileImageURL)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case plan
        case gender
        case dateOfBirth = "date_of_birth"
        case profileImageURL = "profile_image_url"
        case isPrivate = "is_private"
        case isActive = "is_active"
        case isVerified = "is_verified"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case followersCount = "followers_count"
        case followingCount = "following_count"
    }

    private func isBlank(_ value: String?) -> Bool {
        guard let value else { return true }
        return value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
