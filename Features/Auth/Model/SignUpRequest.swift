//
//  SignUpRequest.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import Foundation

nonisolated struct SignUpRequest: Sendable {
    let username: String
    let password: String
    let email: String
}

nonisolated extension SignUpRequest: Encodable {}
