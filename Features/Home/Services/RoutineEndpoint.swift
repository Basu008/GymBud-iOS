//
//  RoutineEndpoint.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import Foundation

nonisolated enum RoutineEndpoint: Sendable {
    case routines(accessToken: String)
}

nonisolated extension RoutineEndpoint: APIEndpoint {
    nonisolated var path: String {
        switch self {
        case .routines:
            return "routines"
        }
    }

    nonisolated var method: HTTPMethod {
        switch self {
        case .routines:
            return .get
        }
    }

    nonisolated var headers: [String: String] {
        switch self {
        case .routines(let accessToken):
            return ["Authorization": "Bearer \(accessToken)"]
        }
    }
}
