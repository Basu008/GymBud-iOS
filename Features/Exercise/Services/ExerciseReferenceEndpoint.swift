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
    case create(CreateExerciseRequest)
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
        case .create:
            return "exercises"
        }
    }

    nonisolated var method: HTTPMethod {
        switch self {
        case .categories, .muscles, .equipments, .difficulty:
            return .get
        case .create:
            return .post
        }
    }

    nonisolated var headers: [String: String] {
        switch self {
        case .categories, .muscles, .equipments, .difficulty:
            return [:]
        case .create:
            return ["Content-Type": "application/json"]
        }
    }

    nonisolated var body: Data? {
        switch self {
        case .categories, .muscles, .equipments, .difficulty:
            return nil
        case .create(let request):
            return try? JSONEncoder().encode(request)
        }
    }
}
