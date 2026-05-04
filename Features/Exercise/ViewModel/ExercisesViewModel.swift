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
    @Published private(set) var isLoadingMore = false
    @Published var selectedCategoryName = "All"
    @Published var searchText = ""
    @Published var errorMessage: String?

    var filteredExercises: [Exercise] {
        exercises
    }

    var filterNames: [String] {
        ["All"] + categories.map(\.name).deduplicatedCaseInsensitive
    }

    private let service: any ExerciseReferenceServiceProtocol
    private let authTokenStore: any AuthTokenStoreProtocol
    private var currentPage = 1
    private var canLoadMorePages = true

    init(
        selectedExercises: [Exercise] = [],
        service: any ExerciseReferenceServiceProtocol = ExerciseReferenceService(),
        authTokenStore: any AuthTokenStoreProtocol = AuthTokenStore()
    ) {
        self.selectedExercises = selectedExercises
        self.service = service
        self.authTokenStore = authTokenStore
    }

    func loadInitialData() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        currentPage = 1
        canLoadMorePages = true

        defer {
            isLoading = false
        }

        do {
            async let exerciseValues = fetchExercises()
            async let categoryValues = service.categories()

            applyFetchedExercises(try await exerciseValues)
            categories = try await categoryValues
        } catch {
            errorMessage = "Unable to load exercises."
        }
    }

    func refreshExercises() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        currentPage = 1
        canLoadMorePages = true

        defer {
            isLoading = false
        }

        do {
            applyFetchedExercises(try await fetchExercises())
        } catch {
            errorMessage = "Unable to load exercises."
        }
    }

    func isSelected(_ exercise: Exercise) -> Bool {
        selectedExercises.contains { $0.id == exercise.id }
    }

    func toggleSelection(for exercise: Exercise) {
        if isSelected(exercise) {
            selectedExercises.removeAll { $0.id == exercise.id }
        } else {
            selectedExercises.append(exercise)
        }
    }

    func selectExercise(_ exercise: Exercise) {
        selectedExercises.removeAll { $0.id == exercise.id }
        selectedExercises.append(exercise)
    }

    func loadMoreExercisesIfNeeded(currentExercise: Exercise) async {
        guard currentExercise.id == filteredExercises.last?.id,
              canLoadMorePages,
              !isLoading,
              !isLoadingMore
        else {
            return
        }

        isLoadingMore = true
        defer {
            isLoadingMore = false
        }

        do {
            let nextPage = currentPage + 1
            let nextExercises = try await fetchExercises(page: nextPage)
            canLoadMorePages = !nextExercises.isEmpty
            currentPage = nextPage
            appendFetchedExercises(nextExercises)
        } catch {
            canLoadMorePages = false
        }
    }

    private func fetchExercises(page: Int = 1) async throws -> [Exercise] {
        guard let accessToken = authTokenStore.accessToken,
              !accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return []
        }

        let category = selectedCategoryName == "All" ? nil : selectedCategoryName

        return try await service.exercises(
            category: category,
            name: searchText,
            page: page,
            accessToken: accessToken
        )
    }

    private func applyFetchedExercises(_ fetchedExercises: [Exercise]) {
        exercises = fetchedExercises

        selectedExercises = selectedExercises.map { selectedExercise in
            fetchedExercises.first { $0.id == selectedExercise.id } ?? selectedExercise
        }
    }

    private func appendFetchedExercises(_ fetchedExercises: [Exercise]) {
        let existingIDs = Set(exercises.map(\.id))
        exercises.append(contentsOf: fetchedExercises.filter { !existingIDs.contains($0.id) })

        selectedExercises = selectedExercises.map { selectedExercise in
            exercises.first { $0.id == selectedExercise.id } ?? selectedExercise
        }
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
