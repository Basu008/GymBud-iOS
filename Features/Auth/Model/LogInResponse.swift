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
