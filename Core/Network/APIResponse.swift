//
//  APIResponse.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import Foundation

nonisolated struct APIResponse<Payload: Decodable & Sendable>: Sendable {
    let success: Bool
    let payload: Payload?
    let errors: [String]?
    let error: String?

    var errorMessages: [String] {
        if let errors, !errors.isEmpty {
            return errors
        }

        if let error, !error.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return [error]
        }

        return []
    }

    func requirePayload() throws -> Payload {
        guard success, let payload else {
            throw APIResponseError.unsuccessfulResponse(messages: errorMessages)
        }

        return payload
    }
}

nonisolated extension APIResponse: Decodable {}

nonisolated struct APIErrorResponse: Decodable, Sendable {
    let success: Bool?
    let errors: [String]?
    let error: String?

    var messages: [String] {
        if let errors, !errors.isEmpty {
            return errors
        }

        if let error, !error.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return [error]
        }

        return []
    }
}

nonisolated enum APIResponseError: Error, Sendable {
    case unsuccessfulResponse(messages: [String])
}
