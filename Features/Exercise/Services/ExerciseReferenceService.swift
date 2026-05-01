//
//  ExerciseReferenceService.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import Foundation

nonisolated protocol ExerciseReferenceServiceProtocol: Sendable {
    nonisolated func categories() async throws -> [ExerciseReferenceOption]
    nonisolated func muscles() async throws -> [ExerciseReferenceOption]
    nonisolated func equipments() async throws -> [ExerciseReferenceOption]
    nonisolated func difficulties() async throws -> [ExerciseReferenceOption]
    nonisolated func createExercise(_ request: CreateExerciseRequest) async throws -> CustomExercise
}

nonisolated final class ExerciseReferenceService: Sendable {
    private let apiClient: any APIClientProtocol

    nonisolated init(apiClient: any APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }

    nonisolated func categories() async throws -> [ExerciseReferenceOption] {
        try await referenceOptions(from: .categories)
    }

    nonisolated func muscles() async throws -> [ExerciseReferenceOption] {
        try await referenceOptions(from: .muscles)
    }

    nonisolated func equipments() async throws -> [ExerciseReferenceOption] {
        try await referenceOptions(from: .equipments)
    }

    nonisolated func difficulties() async throws -> [ExerciseReferenceOption] {
        try await referenceOptions(from: .difficulty)
    }

    nonisolated func createExercise(_ request: CreateExerciseRequest) async throws -> CustomExercise {
        let response = try await apiClient.request(
            ExerciseReferenceEndpoint.create(request),
            responseType: APIResponse<CreateExercisePayload>.self
        )

        return try response.requirePayload().exercise
    }

    private func referenceOptions(from endpoint: ExerciseReferenceEndpoint) async throws -> [ExerciseReferenceOption] {
        let data = try await apiClient.request(endpoint)
        let decoder = JSONDecoder()

        if let response = try? decoder.decode(APIResponse<ExerciseReferencePayload>.self, from: data) {
            return try response.requirePayload().values
        }

        if let payload = try? decoder.decode(ExerciseReferencePayload.self, from: data) {
            return payload.values
        }

        return try decoder.decode([ExerciseReferenceOption].self, from: data)
    }
}

nonisolated extension ExerciseReferenceService: ExerciseReferenceServiceProtocol {}
