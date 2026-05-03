//
//  Routine.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import Foundation

nonisolated struct CreateRoutineRequest: Encodable, Sendable {
    let name: String
    let exercises: [CreateRoutineExerciseRequest]
}

nonisolated struct CreateRoutineExerciseRequest: Encodable, Sendable {
    let exerciseID: String
    let orderIndex: Int
    let sets: [CreateRoutineSetRequest]

    enum CodingKeys: String, CodingKey {
        case exerciseID = "exercise_id"
        case orderIndex = "order_index"
        case sets
    }
}

nonisolated struct CreateRoutineSetRequest: Encodable, Sendable {
    let setNumber: Int
    let minReps: Int
    let maxReps: Int
    let targetWeightKG: Double

    enum CodingKeys: String, CodingKey {
        case setNumber = "set_number"
        case minReps = "min_reps"
        case maxReps = "max_reps"
        case targetWeightKG = "target_weight_kg"
    }
}

nonisolated struct CreateRoutinePayload: Decodable, Sendable {
    let routine: Routine
}

nonisolated struct UpdateRoutinePayload: Decodable, Sendable {
    let routine: Routine
}

nonisolated struct DeleteRoutinePayload: Decodable, Sendable {
    let deletedID: String

    enum CodingKeys: String, CodingKey {
        case deletedID = "deleted_id"
    }
}

nonisolated struct Routine: Identifiable, Decodable, Sendable {
    let id: String
    let userID: String
    let name: String
    let exercises: [RoutineExercise]
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case name
        case exercises
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

nonisolated struct RoutineExercise: Identifiable, Decodable, Sendable {
    let id: String
    let routineID: String
    let exerciseID: String
    let orderIndex: Int
    let exercise: Exercise
    let sets: [RoutineSet]
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case routineID = "routine_id"
        case exerciseID = "exercise_id"
        case orderIndex = "order_index"
        case exercise
        case sets
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

nonisolated struct RoutineSet: Identifiable, Decodable, Sendable {
    let id: String
    let routineExerciseID: String
    let setNumber: Int
    let minReps: Int
    let maxReps: Int
    let targetWeightKG: Double
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case routineExerciseID = "routine_exercise_id"
        case setNumber = "set_number"
        case minReps = "min_reps"
        case maxReps = "max_reps"
        case targetWeightKG = "target_weight_kg"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

extension Routine {
    static let sampleRoutines: [Routine] = [
        Routine.sample(id: "routine-1", name: "Heavy Push Day", exerciseCount: 8),
        Routine.sample(id: "routine-2", name: "Leg Hypertrophy", exerciseCount: 10),
        Routine.sample(id: "routine-3", name: "Upper Body Power", exerciseCount: 7),
        Routine.sample(id: "routine-4", name: "Active Recovery", exerciseCount: 4)
    ]

    static func sample(id: String, name: String, exerciseCount: Int) -> Routine {
        Routine(
            id: id,
            userID: "user-1",
            name: name,
            exercises: (0..<exerciseCount).map { RoutineExercise.sample(index: $0, routineID: id) },
            createdAt: "",
            updatedAt: ""
        )
    }
}

private extension RoutineExercise {
    static func sample(index: Int, routineID: String) -> RoutineExercise {
        let exerciseID = "exercise-\(index + 1)"

        return RoutineExercise(
            id: "routine-exercise-\(index + 1)",
            routineID: routineID,
            exerciseID: exerciseID,
            orderIndex: index,
            exercise: Exercise.sample(id: exerciseID, index: index),
            sets: [RoutineSet.sample(index: index)],
            createdAt: "",
            updatedAt: ""
        )
    }
}

private extension Exercise {
    static func sample(id: String, index: Int) -> Exercise {
        Exercise(
            id: id,
            name: "Exercise \(index + 1)",
            category: "",
            equipment: "",
            primaryMuscle: "",
            secondaryMuscles: [],
            difficulty: "",
            movementMode: "",
            isActive: true,
            createdAt: "",
            updatedAt: ""
        )
    }
}

private extension RoutineSet {
    static func sample(index: Int) -> RoutineSet {
        RoutineSet(
            id: "set-\(index + 1)",
            routineExerciseID: "routine-exercise-\(index + 1)",
            setNumber: 1,
            minReps: 8,
            maxReps: 12,
            targetWeightKG: 0,
            createdAt: "",
            updatedAt: ""
        )
    }
}
