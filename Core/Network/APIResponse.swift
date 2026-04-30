//
//  APIResponse.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import Foundation

nonisolated struct APIResponse<Payload: Decodable & Sendable>: Sendable {
    let success: Bool
    let payload: Payload
}

nonisolated extension APIResponse: Decodable {}
