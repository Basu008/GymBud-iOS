//
//  Exercise.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import Foundation

nonisolated struct CreateExerciseRequest: Encodable, Sendable {
    let name: String
    let category: String
    let equipment: String
    let primaryMuscle: String
    let secondaryMuscles: [String]
    let difficulty: String
    let movementMode: String

    private enum CodingKeys: String, CodingKey {
        case name
        case category
        case equipment
        case primaryMuscle = "primary_muscle"
        case secondaryMuscles = "secondary_muscles"
        case difficulty
        case movementMode = "movement_mode"
    }
}

nonisolated struct CreateExercisePayload: Decodable, Sendable {
    let exercise: Exercise
}

nonisolated struct Exercise: Identifiable, Decodable, Sendable {
    let id: String
    let name: String
    let category: String?
    let equipment: String?
    let primaryMuscle: String?
    let secondaryMuscles: [String]
    let difficulty: String?
    let movementMode: String?
    let isActive: Bool
    let createdAt: String?
    let updatedAt: String?

    nonisolated init(
        id: String,
        name: String,
        category: String? = nil,
        equipment: String? = nil,
        primaryMuscle: String? = nil,
        secondaryMuscles: [String] = [],
        difficulty: String? = nil,
        movementMode: String? = nil,
        isActive: Bool = true,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.equipment = equipment
        self.primaryMuscle = primaryMuscle
        self.secondaryMuscles = secondaryMuscles
        self.difficulty = difficulty
        self.movementMode = movementMode
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try Self.firstString(in: container, keys: [.id, .mongoID]) ?? UUID().uuidString
        let name = try Self.firstString(in: container, keys: [.name]) ?? "Unnamed Exercise"

        self.init(
            id: id,
            name: name,
            category: try Self.firstString(in: container, keys: [.category]),
            equipment: try Self.firstString(in: container, keys: [.equipment]),
            primaryMuscle: try Self.firstString(in: container, keys: [.primaryMuscle]),
            secondaryMuscles: try Self.secondaryMuscles(in: container),
            difficulty: try Self.firstString(in: container, keys: [.difficulty]),
            movementMode: try Self.firstString(in: container, keys: [.movementMode, .movementMethod]),
            isActive: try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true,
            createdAt: try Self.firstString(in: container, keys: [.createdAt]),
            updatedAt: try Self.firstString(in: container, keys: [.updatedAt])
        )
    }

    private static func firstString(
        in container: KeyedDecodingContainer<CodingKeys>,
        keys: [CodingKeys]
    ) throws -> String? {
        for key in keys {
            if let value = try container.decodeIfPresent(String.self, forKey: key),
               !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return value
            }
        }

        return nil
    }

    private static func secondaryMuscles(in container: KeyedDecodingContainer<CodingKeys>) throws -> [String] {
        if let values = try container.decodeIfPresent([String].self, forKey: .secondaryMuscles) {
            return values.filteredExerciseTags
        }

        if let values = try container.decodeIfPresent([String].self, forKey: .secondaryMuscle) {
            return values.filteredExerciseTags
        }

        if let value = try container.decodeIfPresent(String.self, forKey: .secondaryMuscles) {
            return value
                .split(separator: ",")
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filteredExerciseTags
        }

        if let value = try container.decodeIfPresent(String.self, forKey: .secondaryMuscle) {
            return value
                .split(separator: ",")
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filteredExerciseTags
        }

        return []
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case mongoID = "_id"
        case name
        case category
        case equipment
        case primaryMuscle = "primary_muscle"
        case secondaryMuscle = "secondary_muscle"
        case secondaryMuscles = "secondary_muscles"
        case difficulty
        case movementMode = "movement_mode"
        case movementMethod = "movement_method"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

nonisolated struct ExercisesPayload: Decodable, Sendable {
    let exercises: [Exercise]

    nonisolated init(from decoder: Decoder) throws {
        if let exercises = try? [Exercise](from: decoder) {
            self.exercises = exercises
            return
        }

        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        var decodedExercises: [Exercise] = []

        for key in container.allKeys {
            if let exercises = try? container.decode([Exercise].self, forKey: key) {
                decodedExercises.append(contentsOf: exercises)
            }
        }

        exercises = decodedExercises
    }
}

nonisolated private extension Array where Element == String {
    var filteredExerciseTags: [String] {
        filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
}

private struct DynamicCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}
