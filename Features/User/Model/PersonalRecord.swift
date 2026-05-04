//
//  PersonalRecord.swift
//  GymBud
//
//  Created by Codex on 04/05/26.
//

import Foundation

nonisolated struct PersonalRecordsPayload: Decodable, Sendable {
    let personalRecords: [PersonalRecord]
    let pagination: PersonalRecordsPagination

    enum CodingKeys: String, CodingKey {
        case personalRecords = "personal_records"
        case pagination
    }
}

nonisolated struct PersonalRecord: Identifiable, Decodable, Sendable {
    let id: String
    let userID: String
    let exerciseID: String
    let exerciseName: String
    let bestWeightKG: Double
    let bestReps: Int
    let estimated1RM: Double
    let workoutID: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case exerciseID = "exercise_id"
        case exerciseName = "exercise_name"
        case bestWeightKG = "best_weight_kg"
        case bestReps = "best_reps"
        case estimated1RM = "estimated_1rm"
        case workoutID = "workout_id"
        case updatedAt = "updated_at"
    }
}

nonisolated struct PersonalRecordsPagination: Decodable, Sendable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case page
        case limit
        case total
        case totalPages = "total_pages"
    }
}
