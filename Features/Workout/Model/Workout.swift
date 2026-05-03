//
//  Workout.swift
//  GymBud
//
//  Created by Codex on 03/05/26.
//

import Foundation

nonisolated struct LatestWorkoutPayload: Decodable, Sendable {
    let workout: WorkoutLog?
}

nonisolated struct CompleteWorkoutPayload: Decodable, Sendable {
    let workout: WorkoutLog
}

nonisolated struct CompleteWorkoutRequest: Encodable, Sendable {
    let routineID: String
    let startTime: String
    let endTime: String
    let visibility: String
    let exercises: [CompleteWorkoutExerciseRequest]

    enum CodingKeys: String, CodingKey {
        case routineID = "routine_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case visibility
        case exercises
    }
}

nonisolated struct CompleteWorkoutExerciseRequest: Encodable, Sendable {
    let exerciseID: String
    let sets: [CompleteWorkoutSetRequest]

    enum CodingKeys: String, CodingKey {
        case exerciseID = "exercise_id"
        case sets
    }
}

nonisolated struct CompleteWorkoutSetRequest: Encodable, Sendable {
    let setNumber: Int
    let actualReps: Int
    let actualWeightKG: Double

    enum CodingKeys: String, CodingKey {
        case setNumber = "set_number"
        case actualReps = "actual_reps"
        case actualWeightKG = "actual_weight_kg"
    }
}

nonisolated struct WorkoutLog: Identifiable, Decodable, Sendable {
    let id: String
    let userID: String
    let routineID: String
    let title: String
    let startedAt: String
    let endedAt: String?
    let durationSec: Int
    let visibility: String
    let exercises: [WorkoutExerciseLog]
    let stats: WorkoutStats?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case routineID = "routine_id"
        case title
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case durationSec = "duration_sec"
        case visibility
        case exercises
        case stats
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

nonisolated struct WorkoutExerciseLog: Identifiable, Decodable, Sendable {
    var id: String { exerciseID }

    let exerciseID: String
    let exerciseName: String
    let orderIndex: Int
    let sets: [WorkoutSetLog]

    enum CodingKeys: String, CodingKey {
        case exerciseID = "exercise_id"
        case exerciseName = "exercise_name"
        case orderIndex = "order_index"
        case sets
    }
}

nonisolated struct WorkoutSetLog: Identifiable, Decodable, Sendable {
    var id: Int { setNumber }

    let setNumber: Int
    let plannedMinReps: Int?
    let plannedMaxReps: Int?
    let plannedWeightKG: Double?
    let actualReps: Int?
    let actualWeightKG: Double?

    enum CodingKeys: String, CodingKey {
        case setNumber = "set_number"
        case plannedMinReps = "planned_min_reps"
        case plannedMaxReps = "planned_max_reps"
        case plannedWeightKG = "planned_weight_kg"
        case actualReps = "actual_reps"
        case actualWeightKG = "actual_weight_kg"
    }
}

nonisolated struct WorkoutStats: Decodable, Sendable {
    let totalSets: Int
    let totalReps: Int
    let totalVolume: Double

    enum CodingKeys: String, CodingKey {
        case totalSets = "total_sets"
        case totalReps = "total_reps"
        case totalVolume = "total_volume"
    }
}
