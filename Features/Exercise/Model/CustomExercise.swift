//
//  CustomExercise.swift
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
    let secondaryMuscles: String
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
    let exercise: CustomExercise
}

nonisolated struct CustomExercise: Identifiable, Decodable, Sendable {
    let id: String
    let name: String
    let category: String
    let equipment: String
    let primaryMuscle: String
    let secondaryMuscles: String
    let difficulty: String
    let movementMode: String
    let isActive: Bool
    let createdAt: String
    let updatedAt: String

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case equipment
        case primaryMuscle = "primary_muscle"
        case secondaryMuscles = "secondary_muscles"
        case difficulty
        case movementMode = "movement_mode"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
