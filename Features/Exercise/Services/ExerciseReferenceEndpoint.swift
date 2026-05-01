//
//  ExerciseReferenceEndpoint.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import Foundation

nonisolated enum ExerciseReferenceEndpoint: Sendable {
    case categories
    case muscles
    case equipments
    case difficulty
    case exercises(category: String?, name: String?, accessToken: String)
    case create(CreateExerciseRequest, accessToken: String)
}

nonisolated extension ExerciseReferenceEndpoint: APIEndpoint {
    nonisolated var path: String {
        switch self {
        case .categories:
            return "exercises/categories"
        case .muscles:
            return "exercises/muscles"
        case .equipments:
            return "exercises/equipments"
        case .difficulty:
            return "exercises/difficulty"
        case .exercises:
            return "exercises"
        case .create:
            return "exercises"
        }
    }

    nonisolated var method: HTTPMethod {
        switch self {
        case .categories, .muscles, .equipments, .difficulty, .exercises:
            return .get
        case .create:
            return .post
        }
    }

    nonisolated var queryItems: [URLQueryItem] {
        switch self {
        case .exercises(let category, let name, _):
            return [
                Self.queryItem(name: "category", value: category),
                Self.queryItem(name: "name", value: name)
            ].compactMap { $0 }
        case .categories, .muscles, .equipments, .difficulty, .create:
            return []
        }
    }

    nonisolated var headers: [String: String] {
        switch self {
        case .categories, .muscles, .equipments, .difficulty:
            return [:]
        case .exercises(_, _, let accessToken):
            return ["Authorization": "Bearer \(accessToken)"]
        case .create(_, let accessToken):
            return [
                "Authorization": "Bearer \(accessToken)",
                "Content-Type": "application/json"
            ]
        }
    }

    nonisolated var body: Data? {
        switch self {
        case .categories, .muscles, .equipments, .difficulty, .exercises:
            return nil
        case .create(let request, _):
            return try? JSONEncoder().encode(request)
        }
    }

    private static func queryItem(name: String, value: String?) -> URLQueryItem? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty
        else {
            return nil
        }

        return URLQueryItem(name: name, value: value.lowercased())
    }
}
