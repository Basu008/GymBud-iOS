//
//  UpdateProfileRequest.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import Foundation

nonisolated struct UpdateProfileRequest: Encodable, Sendable {
    let displayName: String
    let gender: String
    let dateOfBirth: String
    let profileImageURL: String?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case gender
        case dateOfBirth = "date_of_birth"
        case profileImageURL = "profile_image_url"
    }
}
