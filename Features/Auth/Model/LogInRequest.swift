//
//  LogInRequest.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import Foundation

nonisolated struct LogInRequest: Sendable {
    let username: String
    let password: String
}

nonisolated extension LogInRequest: Encodable {}
