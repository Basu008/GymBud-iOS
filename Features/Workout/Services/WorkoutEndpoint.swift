//
//  WorkoutEndpoint.swift
//  GymBud
//
//  Created by Codex on 03/05/26.
//

import Foundation

nonisolated enum WorkoutEndpoint: Sendable {
    case latestWorkout(routineID: String, accessToken: String)
    case completeWorkout(CompleteWorkoutRequest, accessToken: String)
}

nonisolated extension WorkoutEndpoint: APIEndpoint {
    nonisolated var path: String {
        switch self {
        case .latestWorkout(let routineID, _):
            return "routines/\(routineID)/workouts/latest"
        case .completeWorkout:
            return "workouts"
        }
    }

    nonisolated var method: HTTPMethod {
        switch self {
        case .latestWorkout:
            return .get
        case .completeWorkout:
            return .post
        }
    }

    nonisolated var headers: [String: String] {
        switch self {
        case .latestWorkout(_, let accessToken):
            return ["Authorization": "Bearer \(accessToken)"]
        case .completeWorkout(_, let accessToken):
            return [
                "Authorization": "Bearer \(accessToken)",
                "Content-Type": "application/json"
            ]
        }
    }

    nonisolated var body: Data? {
        switch self {
        case .latestWorkout:
            return nil
        case .completeWorkout(let request, _):
            return try? JSONEncoder().encode(request)
        }
    }
}
