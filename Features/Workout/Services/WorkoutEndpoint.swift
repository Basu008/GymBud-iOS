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
    case analytics(accessToken: String)
    case userWorkouts(userID: String, page: Int, accessToken: String)
    case deleteWorkout(id: String, accessToken: String)
}

nonisolated extension WorkoutEndpoint: APIEndpoint {
    nonisolated var path: String {
        switch self {
        case .latestWorkout(let routineID, _):
            return "routines/\(routineID)/workouts/latest"
        case .completeWorkout:
            return "workouts"
        case .analytics:
            return "users/me/workouts/analytics"
        case .userWorkouts(let userID, _, _):
            return "users/\(userID)/workouts"
        case .deleteWorkout(let id, _):
            return "workouts/\(id)"
        }
    }

    nonisolated var method: HTTPMethod {
        switch self {
        case .latestWorkout, .analytics, .userWorkouts:
            return .get
        case .completeWorkout:
            return .post
        case .deleteWorkout:
            return .delete
        }
    }

    nonisolated var queryItems: [URLQueryItem] {
        switch self {
        case .userWorkouts(_, let page, _):
            return [URLQueryItem(name: "page", value: "\(max(page, 1))")]
        case .latestWorkout, .completeWorkout, .analytics, .deleteWorkout:
            return []
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
        case .analytics(let accessToken):
            return ["Authorization": "Bearer \(accessToken)"]
        case .userWorkouts(_, _, let accessToken):
            return ["Authorization": "Bearer \(accessToken)"]
        case .deleteWorkout(_, let accessToken):
            return ["Authorization": "Bearer \(accessToken)"]
        }
    }

    nonisolated var body: Data? {
        switch self {
        case .latestWorkout, .analytics, .userWorkouts, .deleteWorkout:
            return nil
        case .completeWorkout(let request, _):
            return try? JSONEncoder().encode(request)
        }
    }
}
