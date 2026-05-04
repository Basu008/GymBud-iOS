//
//  AuthenticatedUser.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import Foundation

nonisolated struct AuthenticatedUser: Decodable, Sendable {
    let id: String
    let username: String
    let email: String
    let plan: String
    let bio: String?
    let displayName: String?
    let gender: String?
    let dateOfBirth: String?
    let profileImageURL: String?
    let heightCM: Double?
    let weightKG: Double?
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
        case bio
        case displayName = "display_name"
        case gender
        case dateOfBirth = "date_of_birth"
        case profileImageURL = "profile_image_url"
        case heightCM = "height_cm"
        case weightKG = "weight_kg"
        case bodyMetric = "body_metric"
        case bodyMetrics = "body_metrics"
        case isPrivate = "is_private"
        case isActive = "is_active"
        case isVerified = "is_verified"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case followersCount = "followers_count"
        case followingCount = "following_count"
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        email = try container.decode(String.self, forKey: .email)
        plan = try container.decode(String.self, forKey: .plan)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        gender = try container.decodeIfPresent(String.self, forKey: .gender)
        dateOfBirth = try container.decodeIfPresent(String.self, forKey: .dateOfBirth)
        profileImageURL = try container.decodeIfPresent(String.self, forKey: .profileImageURL)
        isPrivate = try container.decode(Bool.self, forKey: .isPrivate)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        isVerified = try container.decode(Bool.self, forKey: .isVerified)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        followersCount = try container.decode(Int.self, forKey: .followersCount)
        followingCount = try container.decode(Int.self, forKey: .followingCount)

        let directHeight = try container.decodeIfPresent(Double.self, forKey: .heightCM)
        let directWeight = try container.decodeIfPresent(Double.self, forKey: .weightKG)
        let bodyMetric = try container.decodeIfPresent(BodyMetricSnapshot.self, forKey: .bodyMetric)
        let bodyMetricsObject = try? container.decodeIfPresent(BodyMetricSnapshot.self, forKey: .bodyMetrics)
        let latestBodyMetric = bodyMetricsObject ?? ((try? container.decodeIfPresent([BodyMetricSnapshot].self, forKey: .bodyMetrics))?.first ?? nil)

        heightCM = directHeight ?? bodyMetric?.heightCM ?? latestBodyMetric?.heightCM
        weightKG = directWeight ?? bodyMetric?.weightKG ?? latestBodyMetric?.weightKG
    }

    private func isBlank(_ value: String?) -> Bool {
        guard let value else { return true }
        return value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private nonisolated struct BodyMetricSnapshot: Decodable, Sendable {
    let heightCM: Double?
    let weightKG: Double?

    enum CodingKeys: String, CodingKey {
        case heightCM = "height_cm"
        case weightKG = "weight_kg"
    }
}
