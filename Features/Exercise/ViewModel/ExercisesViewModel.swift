//
//  ExercisesViewModel.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import Combine
import Foundation

@MainActor
final class ExercisesViewModel: ObservableObject {
    @Published private(set) var exercises: [Exercise] = []
    @Published private(set) var selectedExercises: [Exercise] = []
    @Published private(set) var categories: [ExerciseReferenceOption] = []
    @Published private(set) var isLoading = false
    @Published var selectedCategoryName = "All"
    @Published var searchText = ""
    @Published var errorMessage: String?

    var filteredExercises: [Exercise] {
        selectedExercises + exercises.filter { exercise in
            !selectedExercises.contains { $0.id == exercise.id }
        }
    }

    var filterNames: [String] {
        ["All"] + categories.map(\.name).deduplicatedCaseInsensitive
    }

    private let service: any ExerciseReferenceServiceProtocol
    private let authTokenStore: any AuthTokenStoreProtocol

    init(
        service: any ExerciseReferenceServiceProtocol = ExerciseReferenceService(),
        authTokenStore: any AuthTokenStoreProtocol = AuthTokenStore()
    ) {
        self.service = service
        self.authTokenStore = authTokenStore
    }

    func loadInitialData() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        Self.log("Loading initial exercises and categories.")

        defer {
            isLoading = false
        }

        do {
            async let exerciseValues = fetchExercises()
            async let categoryValues = service.categories()

            applyFetchedExercises(try await exerciseValues)
            categories = try await categoryValues
            Self.log("Loaded \(exercises.count) exercises and \(categories.count) categories.")
        } catch {
            Self.log("Initial load failed: \(error.localizedDescription)")
            errorMessage = "Unable to load exercises."
        }
    }

    func refreshExercises() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        Self.log("Refreshing exercises.")

        defer {
            isLoading = false
        }

        do {
            applyFetchedExercises(try await fetchExercises())
            Self.log("Loaded \(exercises.count) exercises.")
        } catch {
            Self.log("Exercise refresh failed: \(error.localizedDescription)")
            errorMessage = "Unable to load exercises."
        }
    }

    func isSelected(_ exercise: Exercise) -> Bool {
        selectedExercises.contains { $0.id == exercise.id }
    }

    func toggleSelection(for exercise: Exercise) {
        if isSelected(exercise) {
            selectedExercises.removeAll { $0.id == exercise.id }
            Self.log("Deselected exercise id=\(exercise.id)")
        } else {
            selectedExercises.append(exercise)
            Self.log("Selected exercise id=\(exercise.id)")
        }
    }

    func selectExercise(_ exercise: Exercise) {
        selectedExercises.removeAll { $0.id == exercise.id }
        selectedExercises.append(exercise)
        Self.log("Selected created exercise id=\(exercise.id)")
    }

    private func fetchExercises() async throws -> [Exercise] {
        guard let accessToken = authTokenStore.accessToken,
              !accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            Self.log("Skipped exercise fetch because no auth token is stored.")
            return []
        }

        let category = selectedCategoryName == "All" ? nil : selectedCategoryName
        Self.log(
            "Fetching exercises category=\(category ?? "<all>") name=\(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "<empty>" : searchText) tokenPresent=true"
        )

        return try await service.exercises(
            category: category,
            name: searchText,
            accessToken: accessToken
        )
    }

    private func applyFetchedExercises(_ fetchedExercises: [Exercise]) {
        exercises = fetchedExercises

        selectedExercises = selectedExercises.map { selectedExercise in
            fetchedExercises.first { $0.id == selectedExercise.id } ?? selectedExercise
        }
    }

    private static func log(_ message: String) {
        #if DEBUG
        print("[ExercisesViewModel] \(message)")
        #endif
    }
}

extension Exercise {
    var allMuscleTags: [String] {
        ([primaryMuscle].compactMap { $0 } + secondaryMuscles).filter {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}

private extension Array where Element == String {
    var deduplicatedCaseInsensitive: [String] {
        var seen: Set<String> = []

        return filter { value in
            let key = value.lowercased()
            guard !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
    }
}
