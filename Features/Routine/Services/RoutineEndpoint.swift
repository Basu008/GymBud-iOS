//
//  RoutineEndpoint.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import Foundation

nonisolated enum RoutineEndpoint: Sendable {
    case routines(page: Int, accessToken: String)
    case createRoutine(CreateRoutineRequest, accessToken: String)
    case updateRoutine(id: String, CreateRoutineRequest, accessToken: String)
    case deleteRoutine(id: String, accessToken: String)
}

nonisolated extension RoutineEndpoint: APIEndpoint {
    nonisolated var path: String {
        switch self {
        case .routines, .createRoutine:
            return "routines"
        case .updateRoutine(let id, _, _):
            return "routines/\(id)"
        case .deleteRoutine(let id, _):
            return "routines/\(id)"
        }
    }

    nonisolated var method: HTTPMethod {
        switch self {
        case .routines:
            return .get
        case .createRoutine:
            return .post
        case .updateRoutine:
            return .patch
        case .deleteRoutine:
            return .delete
        }
    }

    nonisolated var queryItems: [URLQueryItem] {
        switch self {
        case .routines(let page, _):
            return [URLQueryItem(name: "page", value: "\(max(page, 1))")]
        case .createRoutine, .updateRoutine, .deleteRoutine:
            return []
        }
    }

    nonisolated var headers: [String: String] {
        switch self {
        case .routines(_, let accessToken):
            return ["Authorization": "Bearer \(accessToken)"]
        case .createRoutine(_, let accessToken):
            return [
                "Authorization": "Bearer \(accessToken)",
                "Content-Type": "application/json"
            ]
        case .updateRoutine(_, _, let accessToken):
            return [
                "Authorization": "Bearer \(accessToken)",
                "Content-Type": "application/json"
            ]
        case .deleteRoutine(_, let accessToken):
            return ["Authorization": "Bearer \(accessToken)"]
        }
    }

    nonisolated var body: Data? {
        switch self {
        case .routines, .deleteRoutine:
            return nil
        case .createRoutine(let request, _):
            return try? JSONEncoder().encode(request)
        case .updateRoutine(_, let request, _):
            return try? JSONEncoder().encode(request)
        }
    }
}
