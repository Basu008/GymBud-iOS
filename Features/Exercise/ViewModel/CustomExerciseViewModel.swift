//
//  CustomExerciseViewModel.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import Combine
import Foundation

@MainActor
final class CustomExerciseViewModel: ObservableObject {
    @Published private(set) var categories: [ExerciseReferenceOption] = []
    @Published private(set) var muscles: [ExerciseReferenceOption] = []
    @Published private(set) var equipments: [ExerciseReferenceOption] = []
    @Published private(set) var difficulties: [ExerciseReferenceOption] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published private(set) var createdExercise: CustomExercise?
    @Published var errorMessage: String?
    @Published var successMessage: String?

    @Published var exerciseName = ""
    @Published var selectedCategory: ExerciseReferenceOption?
    @Published var selectedEquipment: ExerciseReferenceOption?
    @Published var selectedPrimaryMuscle: ExerciseReferenceOption?
    @Published var selectedSecondaryMuscles: [ExerciseReferenceOption] = []
    @Published var selectedDifficulty: ExerciseReferenceOption?
    @Published var movementMode = ""

    private let service: any ExerciseReferenceServiceProtocol

    init(service: any ExerciseReferenceServiceProtocol = ExerciseReferenceService()) {
        self.service = service
    }

    func loadReferenceData() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            async let categoryOptions = service.categories()
            async let muscleOptions = service.muscles()
            async let equipmentOptions = service.equipments()
            async let difficultyOptions = service.difficulties()

            categories = try await categoryOptions
            muscles = try await muscleOptions
            equipments = try await equipmentOptions
            difficulties = try await difficultyOptions

            applyDefaultSelections()
        } catch {
            errorMessage = "Unable to load exercise options."
        }
    }

    func selectSecondaryMuscle(_ muscle: ExerciseReferenceOption) {
        guard !selectedSecondaryMuscles.contains(muscle) else { return }
        selectedSecondaryMuscles.append(muscle)
    }

    func removeSecondaryMuscle(_ muscle: ExerciseReferenceOption) {
        selectedSecondaryMuscles.removeAll { $0 == muscle }
    }

    func saveExercise() async {
        guard !isSaving else { return }

        guard let request = makeCreateExerciseRequest() else {
            return
        }

        isSaving = true
        errorMessage = nil
        successMessage = nil

        defer {
            isSaving = false
        }

        do {
            createdExercise = try await service.createExercise(request)
            successMessage = "Exercise saved."
        } catch {
            errorMessage = "Unable to save exercise."
        }
    }

    private func applyDefaultSelections() {
        selectedCategory = selectedCategory ?? option(named: "Strength", in: categories) ?? categories.first
        selectedEquipment = selectedEquipment ?? option(named: "Barbell", in: equipments) ?? equipments.first
        selectedPrimaryMuscle = selectedPrimaryMuscle ?? option(named: "Chest", in: muscles) ?? muscles.first
        selectedDifficulty = selectedDifficulty ?? option(named: "Intermediate", in: difficulties) ?? difficulties.first

        if selectedSecondaryMuscles.isEmpty {
            selectedSecondaryMuscles = ["Triceps", "Shoulders"].compactMap { option(named: $0, in: muscles) }
        }
    }

    private func option(named name: String, in options: [ExerciseReferenceOption]) -> ExerciseReferenceOption? {
        options.first { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }
    }

    private func makeCreateExerciseRequest() -> CreateExerciseRequest? {
        let trimmedName = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            errorMessage = "Exercise name is required."
            successMessage = nil
            return nil
        }

        guard let selectedCategory,
              let selectedEquipment,
              let selectedPrimaryMuscle,
              let selectedDifficulty
        else {
            errorMessage = "Please select all exercise options."
            successMessage = nil
            return nil
        }

        return CreateExerciseRequest(
            name: trimmedName,
            category: selectedCategory.name,
            equipment: selectedEquipment.name,
            primaryMuscle: selectedPrimaryMuscle.name,
            secondaryMuscles: selectedSecondaryMuscles.map(\.name).joined(separator: ", "),
            difficulty: selectedDifficulty.name,
            movementMode: movementMode.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}
