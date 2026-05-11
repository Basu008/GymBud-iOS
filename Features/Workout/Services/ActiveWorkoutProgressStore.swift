//
//  ActiveWorkoutProgressStore.swift
//  GymBud
//
//  Created by Codex on 11/05/26.
//

import Foundation

nonisolated struct ActiveWorkoutProgress: Codable, Sendable {
    let routineID: String
    let routineName: String
    let startedAt: Date
    let currentExerciseIndex: Int
    let skippedExerciseIDs: Set<String>
    let exercises: [ActiveWorkoutExerciseProgress]
    let cachedElapsedSeconds: Int
    let hasReplacedExercises: Bool
    let updatedAt: Date

    var completedExerciseCount: Int {
        exercises.filter { exercise in
            !exercise.sets.isEmpty && exercise.sets.allSatisfy(\.isCompleted)
        }.count
    }

    var totalExerciseCount: Int {
        exercises.count
    }

    var elapsedSeconds: Int { cachedElapsedSeconds }

    enum CodingKeys: String, CodingKey {
        case routineID
        case routineName
        case startedAt
        case currentExerciseIndex
        case skippedExerciseIDs
        case exercises
        case cachedElapsedSeconds
        case hasReplacedExercises
        case updatedAt
    }

    nonisolated init(
        routineID: String,
        routineName: String,
        startedAt: Date,
        currentExerciseIndex: Int,
        skippedExerciseIDs: Set<String>,
        exercises: [ActiveWorkoutExerciseProgress],
        cachedElapsedSeconds: Int,
        hasReplacedExercises: Bool,
        updatedAt: Date
    ) {
        self.routineID = routineID
        self.routineName = routineName
        self.startedAt = startedAt
        self.currentExerciseIndex = currentExerciseIndex
        self.skippedExerciseIDs = skippedExerciseIDs
        self.exercises = exercises
        self.cachedElapsedSeconds = cachedElapsedSeconds
        self.hasReplacedExercises = hasReplacedExercises
        self.updatedAt = updatedAt
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        routineID = try container.decode(String.self, forKey: .routineID)
        routineName = try container.decode(String.self, forKey: .routineName)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        currentExerciseIndex = try container.decode(Int.self, forKey: .currentExerciseIndex)
        skippedExerciseIDs = try container.decodeIfPresent(Set<String>.self, forKey: .skippedExerciseIDs) ?? []
        exercises = try container.decode([ActiveWorkoutExerciseProgress].self, forKey: .exercises)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        cachedElapsedSeconds = try container.decodeIfPresent(Int.self, forKey: .cachedElapsedSeconds)
            ?? max(0, Int(updatedAt.timeIntervalSince(startedAt)))
        hasReplacedExercises = try container.decodeIfPresent(Bool.self, forKey: .hasReplacedExercises) ?? false
    }
}

nonisolated struct ActiveWorkoutExerciseProgress: Codable, Sendable {
    let exerciseID: String
    let orderIndex: Int
    let name: String
    let movementMethod: String?
    let equipment: String?
    let primaryMuscle: String?
    let secondaryMuscles: [String]
    let difficulty: String?
    let sets: [ActiveWorkoutSetProgress]

    enum CodingKeys: String, CodingKey {
        case exerciseID
        case orderIndex
        case name
        case movementMethod
        case equipment
        case primaryMuscle
        case secondaryMuscles
        case difficulty
        case sets
    }

    nonisolated init(
        exerciseID: String,
        orderIndex: Int,
        name: String,
        movementMethod: String?,
        equipment: String?,
        primaryMuscle: String?,
        secondaryMuscles: [String],
        difficulty: String?,
        sets: [ActiveWorkoutSetProgress]
    ) {
        self.exerciseID = exerciseID
        self.orderIndex = orderIndex
        self.name = name
        self.movementMethod = movementMethod
        self.equipment = equipment
        self.primaryMuscle = primaryMuscle
        self.secondaryMuscles = secondaryMuscles
        self.difficulty = difficulty
        self.sets = sets
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        exerciseID = try container.decode(String.self, forKey: .exerciseID)
        orderIndex = try container.decodeIfPresent(Int.self, forKey: .orderIndex) ?? 0
        name = try container.decode(String.self, forKey: .name)
        movementMethod = try container.decodeIfPresent(String.self, forKey: .movementMethod)
        equipment = try container.decodeIfPresent(String.self, forKey: .equipment)
        primaryMuscle = try container.decodeIfPresent(String.self, forKey: .primaryMuscle)
        secondaryMuscles = try container.decodeIfPresent([String].self, forKey: .secondaryMuscles) ?? []
        difficulty = try container.decodeIfPresent(String.self, forKey: .difficulty)
        sets = try container.decode([ActiveWorkoutSetProgress].self, forKey: .sets)
    }
}

nonisolated struct ActiveWorkoutSetProgress: Codable, Sendable {
    let setNumber: Int
    let plannedMinReps: Int
    let plannedMaxReps: Int
    let plannedWeightKG: Double
    let actualRepsText: String
    let actualWeightText: String
    let repsPlaceholderText: String
    let weightPlaceholderText: String
    let isCompleted: Bool
    let hasUserEdited: Bool
}

nonisolated protocol ActiveWorkoutProgressStoreProtocol: Sendable {
    nonisolated func load() -> ActiveWorkoutProgress?
    nonisolated func save(_ progress: ActiveWorkoutProgress)
    nonisolated func clear()
}

nonisolated final class ActiveWorkoutProgressStore: ActiveWorkoutProgressStoreProtocol, @unchecked Sendable {
    static let shared = ActiveWorkoutProgressStore()

    private let key = "workout.activeProgress"
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    nonisolated init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    nonisolated func load() -> ActiveWorkoutProgress? {
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? decoder.decode(ActiveWorkoutProgress.self, from: data)
    }

    nonisolated func save(_ progress: ActiveWorkoutProgress) {
        guard let data = try? encoder.encode(progress) else { return }
        userDefaults.set(data, forKey: key)
    }

    nonisolated func clear() {
        userDefaults.removeObject(forKey: key)
    }
}
