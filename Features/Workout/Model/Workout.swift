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

nonisolated struct WorkoutAnalyticsPayload: Decodable, Sendable {
    let userID: String
    let stats: WorkoutAnalyticsStats

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case stats
    }
}

nonisolated struct WorkoutAnalyticsStats: Decodable, Sendable {
    let workoutsCount: Int
    let totalVolume: Double
    let totalSets: Int
    let totalReps: Int
    let prCount: Int

    enum CodingKeys: String, CodingKey {
        case workoutsCount = "workouts_count"
        case totalVolume = "total_volume"
        case totalSets = "total_sets"
        case totalReps = "total_reps"
        case prCount = "pr_count"
    }
}

nonisolated struct WorkoutListPayload: Decodable, Sendable {
    let workouts: [WorkoutLog]

    enum CodingKeys: String, CodingKey {
        case workouts
    }

    init(from decoder: Decoder) throws {
        if let workouts = try? [WorkoutLog](from: decoder) {
            self.workouts = workouts
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        workouts = try container.decode([WorkoutLog].self, forKey: .workouts)
    }
}

nonisolated struct DeleteWorkoutPayload: Decodable, Sendable {
    let deletedID: String

    enum CodingKeys: String, CodingKey {
        case deletedID = "deleted_id"
    }
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
    let prFlags: WorkoutSetPRFlags?

    enum CodingKeys: String, CodingKey {
        case setNumber = "set_number"
        case plannedMinReps = "planned_min_reps"
        case plannedMaxReps = "planned_max_reps"
        case maxPlannedReps = "max_planned_reps"
        case plannedWeightKG = "planned_weight_kg"
        case plannedWeight = "planned_weight"
        case plannedWeights = "planned_weights"
        case actualReps = "actual_reps"
        case actualWeightKG = "actual_weight_kg"
        case prFlags = "pr_flags"
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        setNumber = try container.decode(Int.self, forKey: .setNumber)
        plannedMinReps = try container.decodeIfPresent(Int.self, forKey: .plannedMinReps)
        plannedMaxReps = try Self.firstInt(in: container, keys: [.plannedMaxReps, .maxPlannedReps])
        plannedWeightKG = try Self.firstDouble(in: container, keys: [.plannedWeightKG, .plannedWeight, .plannedWeights])
        actualReps = try container.decodeIfPresent(Int.self, forKey: .actualReps)
        actualWeightKG = try container.decodeIfPresent(Double.self, forKey: .actualWeightKG)
        prFlags = try container.decodeIfPresent(WorkoutSetPRFlags.self, forKey: .prFlags)
    }

    private static func firstInt(
        in container: KeyedDecodingContainer<CodingKeys>,
        keys: [CodingKeys]
    ) throws -> Int? {
        for key in keys {
            if let value = try container.decodeIfPresent(Int.self, forKey: key) {
                return value
            }
        }

        return nil
    }

    private static func firstDouble(
        in container: KeyedDecodingContainer<CodingKeys>,
        keys: [CodingKeys]
    ) throws -> Double? {
        for key in keys {
            if let value = try container.decodeIfPresent(Double.self, forKey: key) {
                return value
            }
        }

        return nil
    }
}

nonisolated struct WorkoutSetPRFlags: Decodable, Sendable {
    let weightPR: Bool
    let repPR: Bool
    let estimated1RMPR: Bool

    enum CodingKeys: String, CodingKey {
        case weightPR = "weight_pr"
        case repPR = "rep_pr"
        case estimated1RMPR = "estimated_1rm_pr"
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
