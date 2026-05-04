//
//  NewRoutineView.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct NewRoutineView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var routineName = ""
    @State private var exercises: [NewRoutineExerciseDraft] = []
    @State private var isSelectingExercises = false
    @State private var isSaving = false
    @State private var saveErrorMessage: String?
    @State private var draggedExerciseID: UUID?
    private let routineService: any RoutineServiceProtocol

    init(routineService: any RoutineServiceProtocol = RoutineService()) {
        self.routineService = routineService
    }

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Build Routine")
                            .font(AppFonts.Headline.bold(28))
                            .foregroundStyle(AppColors.onBackground)

                        Text("Design your custom training split")
                            .font(AppFonts.Body.medium(13))
                            .foregroundStyle(AppColors.onSurfaceVariant)
                    }

                    routineNameField

                    addExerciseButton

                    VStack(spacing: 18) {
                        ForEach($exercises) { $exercise in
                            NewRoutineExerciseCard(exercise: $exercise) {
                                exercises.removeAll { $0.id == exercise.id }
                            }
                            .onDrag {
                                draggedExerciseID = exercise.id
                                return NSItemProvider(object: exercise.id.uuidString as NSString)
                            }
                            .onDrop(
                                of: [.text],
                                delegate: NewRoutineExerciseDropDelegate(
                                    exercise: exercise,
                                    exercises: $exercises,
                                    draggedExerciseID: $draggedExerciseID
                                )
                            )
                        }
                    }

                }
                .padding(.horizontal, 15)
                .padding(.top, 16)
                .padding(.bottom, 114)
            }
            .scrollIndicators(.hidden)

            VStack {
                Spacer()

                if let saveErrorMessage {
                    Text(saveErrorMessage)
                        .font(AppFonts.Body.bold(12))
                        .foregroundStyle(AppColors.error)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                }

                GBPrimaryButton(
                    title: "SAVE ROUTINE",
                    isLoading: isSaving
                ) {
                    saveRoutine()
                }
                .padding(.horizontal, 15)
                .padding(.bottom, 16)
            }
        }
        .fullScreenCover(isPresented: $isSelectingExercises) {
            ExercisesView(
                selectedExercises: exercises.map(\.exercise),
                onCancel: {
                    isSelectingExercises = false
                },
                onSave: { selectedExercises in
                    applySelectedExercises(selectedExercises)
                    isSelectingExercises = false
                }
            )
        }
        .routineKeyboardDismissToolbar()
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")

            Spacer()
        }
    }

    private var routineNameField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ROUTINE NAME")
                .font(AppFonts.Body.bold(9))
                .tracking(2.2)
                .foregroundStyle(AppColors.onSurfaceVariant)

            TextField("e.g., Heavy Push Day", text: $routineName)
                .font(AppFonts.Body.bold(14))
                .foregroundStyle(AppColors.onBackground)
                .tint(AppColors.primaryFixed)
                .padding(.horizontal, 18)
                .frame(height: 56)
                .background(Color.black.opacity(0.16))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private var addExerciseButton: some View {
        Button {
            isSelectingExercises = true
        } label: {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AppColors.primary.opacity(0.12))

                    Image(systemName: "plus.circle")
                        .font(.system(size: 23, weight: .bold))
                        .foregroundStyle(AppColors.primary)
                }
                .frame(width: 42, height: 42)

                Text("ADD EXERCISES")
                    .font(AppFonts.Body.bold(11))
                    .tracking(2.4)
                    .foregroundStyle(AppColors.onBackground.opacity(0.82))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 112)
            .background(AppColors.surface.opacity(0.76))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(AppColors.outlineVariant.opacity(0.52), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add exercises")
    }

    private func applySelectedExercises(_ selectedExercises: [Exercise]) {
        exercises = selectedExercises.map { selectedExercise in
            exercises.first { $0.exercise.id == selectedExercise.id } ?? NewRoutineExerciseDraft(exercise: selectedExercise)
        }
    }

    private var canSaveRoutine: Bool {
        !routineName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !exercises.isEmpty
    }

    private func saveRoutine() {
        guard !isSaving else { return }

        guard let accessToken = routineService.storedAccessToken(),
              !accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            saveErrorMessage = "Please log in again to save this routine."
            return
        }

        guard let request = makeCreateRoutineRequest() else {
            saveErrorMessage = "Add a routine name and at least one exercise set."
            return
        }

        isSaving = true
        saveErrorMessage = nil

        Task {
            do {
                _ = try await routineService.createRoutine(request, accessToken: accessToken)
                dismiss()
            } catch {
                saveErrorMessage = "Unable to save routine."
            }

            isSaving = false
        }
    }

    private func makeCreateRoutineRequest() -> CreateRoutineRequest? {
        let trimmedRoutineName = routineName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedRoutineName.isEmpty, !exercises.isEmpty else { return nil }

        let exerciseRequests = exercises.enumerated().compactMap { index, exercise -> CreateRoutineExerciseRequest? in
            guard !exercise.sets.isEmpty else { return nil }

            return CreateRoutineExerciseRequest(
                exerciseID: exercise.exercise.id,
                orderIndex: index + 1,
                sets: exercise.sets.map { set in
                    CreateRoutineSetRequest(
                        setNumber: set.number,
                        minReps: set.minReps,
                        maxReps: set.maxReps,
                        targetWeightKG: set.weight
                    )
                }
            )
        }

        guard !exerciseRequests.isEmpty else { return nil }

        return CreateRoutineRequest(
            name: trimmedRoutineName,
            exercises: exerciseRequests
        )
    }

    private var routineImageBand: some View {
        VStack(alignment: .leading, spacing: 2) {
            Spacer()

            Text("BUILD YOUR LEGACY")
                .font(AppFonts.Body.bold(9))
                .tracking(1.2)
                .foregroundStyle(AppColors.primary)

            Text("Precision in every set.")
                .font(AppFonts.Headline.bold(16))
                .foregroundStyle(AppColors.onBackground)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 132)
        .background(
            ZStack {
                LinearGradient(
                    colors: [Color.black.opacity(0.2), Color.black.opacity(0.84)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                HStack(spacing: -18) {
                    ForEach(0..<5, id: \.self) { index in
                        Circle()
                            .stroke(Color.white.opacity(0.12), lineWidth: 11)
                            .frame(width: 72 + CGFloat(index % 2) * 12, height: 72 + CGFloat(index % 2) * 12)
                    }
                }
                .rotationEffect(.degrees(-8))
                .offset(x: 45, y: -8)
                .blur(radius: 0.4)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct EditRoutineView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var routineName: String
    @State private var exercises: [NewRoutineExerciseDraft]
    @State private var isSelectingExercises = false
    @State private var isSaving = false
    @State private var saveErrorMessage: String?
    @State private var draggedExerciseID: UUID?
    private let routine: Routine
    private let routineService: any RoutineServiceProtocol

    init(
        routine: Routine,
        routineService: any RoutineServiceProtocol = RoutineService()
    ) {
        self.routine = routine
        self.routineService = routineService
        _routineName = State(initialValue: routine.name)
        _exercises = State(initialValue: routine.exercises
            .sorted { $0.orderIndex < $1.orderIndex }
            .map(NewRoutineExerciseDraft.init(routineExercise:)))
    }

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Edit Routine")
                            .font(AppFonts.Headline.bold(28))
                            .foregroundStyle(AppColors.onBackground)

                        Text("It's okay to shuffle things up once in a while.")
                            .font(AppFonts.Body.medium(13))
                            .foregroundStyle(AppColors.onSurfaceVariant)
                    }

                    routineNameField

                    addExerciseButton

                    VStack(spacing: 18) {
                        ForEach($exercises) { $exercise in
                            NewRoutineExerciseCard(exercise: $exercise) {
                                exercises.removeAll { $0.id == exercise.id }
                            }
                            .onDrag {
                                draggedExerciseID = exercise.id
                                return NSItemProvider(object: exercise.id.uuidString as NSString)
                            }
                            .onDrop(
                                of: [.text],
                                delegate: NewRoutineExerciseDropDelegate(
                                    exercise: exercise,
                                    exercises: $exercises,
                                    draggedExerciseID: $draggedExerciseID
                                )
                            )
                        }
                    }
                }
                .padding(.horizontal, 15)
                .padding(.top, 16)
                .padding(.bottom, 114)
            }
            .scrollIndicators(.hidden)

            VStack {
                Spacer()

                if let saveErrorMessage {
                    Text(saveErrorMessage)
                        .font(AppFonts.Body.bold(12))
                        .foregroundStyle(AppColors.error)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                }

                GBPrimaryButton(
                    title: "SAVE CHANGES",
                    isLoading: isSaving
                ) {
                    saveRoutine()
                }
                .padding(.horizontal, 15)
                .padding(.bottom, 16)
            }
        }
        .fullScreenCover(isPresented: $isSelectingExercises) {
            ExercisesView(
                selectedExercises: exercises.map(\.exercise),
                onCancel: {
                    isSelectingExercises = false
                },
                onSave: { selectedExercises in
                    applySelectedExercises(selectedExercises)
                    isSelectingExercises = false
                }
            )
        }
        .routineKeyboardDismissToolbar()
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")

            Spacer()
        }
    }

    private var routineNameField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ROUTINE NAME")
                .font(AppFonts.Body.bold(9))
                .tracking(2.2)
                .foregroundStyle(AppColors.onSurfaceVariant)

            TextField("e.g., Heavy Push Day", text: $routineName)
                .font(AppFonts.Body.bold(14))
                .foregroundStyle(AppColors.onBackground)
                .tint(AppColors.primaryFixed)
                .padding(.horizontal, 18)
                .frame(height: 56)
                .background(Color.black.opacity(0.16))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private var addExerciseButton: some View {
        Button {
            isSelectingExercises = true
        } label: {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AppColors.primary.opacity(0.12))

                    Image(systemName: "plus.circle")
                        .font(.system(size: 23, weight: .bold))
                        .foregroundStyle(AppColors.primary)
                }
                .frame(width: 42, height: 42)

                Text("ADD EXERCISES")
                    .font(AppFonts.Body.bold(11))
                    .tracking(2.4)
                    .foregroundStyle(AppColors.onBackground.opacity(0.82))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 112)
            .background(AppColors.surface.opacity(0.76))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(AppColors.outlineVariant.opacity(0.52), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add exercises")
    }

    private func applySelectedExercises(_ selectedExercises: [Exercise]) {
        exercises = selectedExercises.map { selectedExercise in
            exercises.first { $0.exercise.id == selectedExercise.id } ?? NewRoutineExerciseDraft(exercise: selectedExercise)
        }
    }

    private func saveRoutine() {
        guard !isSaving else { return }

        guard let accessToken = routineService.storedAccessToken(),
              !accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            saveErrorMessage = "Please log in again to save this routine."
            return
        }

        guard let request = makeRoutineRequest() else {
            saveErrorMessage = "Add a routine name and at least one exercise set."
            return
        }

        isSaving = true
        saveErrorMessage = nil

        Task {
            do {
                _ = try await routineService.updateRoutine(id: routine.id, request: request, accessToken: accessToken)
                dismiss()
            } catch {
                saveErrorMessage = "Unable to update routine."
            }

            isSaving = false
        }
    }

    private func makeRoutineRequest() -> CreateRoutineRequest? {
        let trimmedRoutineName = routineName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedRoutineName.isEmpty, !exercises.isEmpty else { return nil }

        let exerciseRequests = exercises.enumerated().compactMap { index, exercise -> CreateRoutineExerciseRequest? in
            guard !exercise.sets.isEmpty else { return nil }

            return CreateRoutineExerciseRequest(
                exerciseID: exercise.exercise.id,
                orderIndex: index + 1,
                sets: exercise.sets.enumerated().map { setIndex, set in
                    CreateRoutineSetRequest(
                        setNumber: setIndex + 1,
                        minReps: set.minReps,
                        maxReps: set.maxReps,
                        targetWeightKG: set.weight
                    )
                }
            )
        }

        guard !exerciseRequests.isEmpty else { return nil }

        return CreateRoutineRequest(
            name: trimmedRoutineName,
            exercises: exerciseRequests
        )
    }
}

private struct NewRoutineExerciseCard: View {
    @Binding var exercise: NewRoutineExerciseDraft
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(exercise.name)
                        .font(AppFonts.Headline.bold(19))
                        .foregroundStyle(AppColors.onBackground)

                    Text(exercise.detailText)
                        .font(AppFonts.Body.bold(9))
                        .tracking(0.7)
                        .foregroundStyle(AppColors.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColors.onSurfaceVariant)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(exercise.name)")
            }

            VStack(spacing: 8) {
                NewRoutineSetHeader()

                ForEach($exercise.sets) { $set in
                    NewRoutineSetRow(set: $set)
                }
            }

            Button {
                exercise.sets.append(exercise.nextSet)
            } label: {
                Text("+  ADD SET")
                    .font(AppFonts.Body.bold(10))
                    .tracking(2.4)
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(AppColors.surfaceVariant.opacity(0.36))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 17)
        .padding(.vertical, 19)
        .background(AppColors.surfaceVariant.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct NewRoutineSetHeader: View {
    var body: some View {
        HStack(spacing: 9) {
            NewRoutineSetColumnLabel("SET", width: 33)
            NewRoutineSetColumnLabel("MIN REPS")
            NewRoutineSetColumnLabel("MAX REPS")
            NewRoutineSetColumnLabel("WEIGHT (KG)")
        }
    }
}

private struct NewRoutineSetRow: View {
    @Binding var set: NewRoutineSetDraft

    var body: some View {
        HStack(spacing: 9) {
            Text("\(set.number)")
                .font(AppFonts.Body.bold(14))
                .foregroundStyle(AppColors.onBackground)
                .frame(width: 33, height: 31)

            NewRoutineSetIntField(value: $set.minReps)
            NewRoutineSetIntField(value: $set.maxReps)
            NewRoutineSetWeightField(value: $set.weight)
        }
    }
}

private struct NewRoutineSetColumnLabel: View {
    let title: String
    let width: CGFloat?

    init(_ title: String, width: CGFloat? = nil) {
        self.title = title
        self.width = width
    }

    var body: some View {
        if let width {
            label
                .frame(width: width, alignment: .center)
        } else {
            label
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var label: some View {
        Text(title)
            .font(AppFonts.Body.bold(8))
            .foregroundStyle(AppColors.onSurfaceVariant)
    }
}

private struct NewRoutineSetIntField: View {
    @Binding var value: Int

    var body: some View {
        TextField("", value: $value, format: .number)
            .font(AppFonts.Body.bold(13))
            .foregroundStyle(AppColors.primaryFixed)
            .multilineTextAlignment(.center)
            .keyboardType(.numberPad)
            .submitLabel(.done)
            .tint(AppColors.primaryFixed)
            .frame(maxWidth: .infinity)
            .frame(height: 31)
            .background(AppColors.surface.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

private struct NewRoutineSetWeightField: View {
    @Binding var value: Double

    var body: some View {
        TextField("", value: $value, format: .number.precision(.fractionLength(0...1)))
            .font(AppFonts.Body.bold(13))
            .foregroundStyle(AppColors.primaryFixed)
            .multilineTextAlignment(.center)
            .keyboardType(.decimalPad)
            .submitLabel(.done)
            .tint(AppColors.primaryFixed)
            .frame(maxWidth: .infinity)
            .frame(height: 31)
            .background(AppColors.surface.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

private struct NewRoutineExerciseDraft: Identifiable {
    let id = UUID()
    let exercise: Exercise
    var sets: [NewRoutineSetDraft]

    var name: String {
        exercise.name
    }

    var detailText: String {
        let secondaryMuscles = exercise.secondaryMuscles.joined(separator: ", ")
        let details = [exercise.category, secondaryMuscles]
            .compactMap { value in
                let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmedValue?.isEmpty == false ? trimmedValue : nil
            }

        return details.isEmpty ? "No exercise details" : details.joined(separator: " | ").uppercased()
    }

    nonisolated init(
        exercise: Exercise,
        sets: [NewRoutineSetDraft] = [NewRoutineSetDraft(number: 1, minReps: 8, maxReps: 10, weight: 0)]
    ) {
        self.exercise = exercise
        self.sets = sets
    }

    nonisolated init(routineExercise: RoutineExercise) {
        let orderedSets = routineExercise.sets
            .sorted { $0.setNumber < $1.setNumber }
            .enumerated()
            .map { index, set in
                NewRoutineSetDraft(
                    number: index + 1,
                    minReps: set.minReps,
                    maxReps: set.maxReps,
                    weight: set.targetWeightKG
                )
            }

        self.init(
            exercise: routineExercise.exercise,
            sets: orderedSets.isEmpty ? [NewRoutineSetDraft(number: 1, minReps: 8, maxReps: 10, weight: 0)] : orderedSets
        )
    }

    var nextSet: NewRoutineSetDraft {
        let previous = sets.last ?? NewRoutineSetDraft(number: 0, minReps: 8, maxReps: 10, weight: 0)
        return NewRoutineSetDraft(
            number: sets.count + 1,
            minReps: previous.minReps,
            maxReps: previous.maxReps,
            weight: previous.weight
        )
    }

}

private struct NewRoutineSetDraft: Identifiable {
    let id = UUID()
    let number: Int
    var minReps: Int
    var maxReps: Int
    var weight: Double

    nonisolated init(number: Int, minReps: Int, maxReps: Int, weight: Double) {
        self.number = number
        self.minReps = minReps
        self.maxReps = maxReps
        self.weight = weight
    }

    var weightText: String {
        weight.formatted(.number.precision(.fractionLength(weight.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 1)))
    }
}

private extension View {
    func routineKeyboardDismissToolbar() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button("Done") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                }
                .font(AppFonts.Body.bold(14))
                .foregroundStyle(AppColors.primaryFixed)
            }
        }
    }
}

private struct NewRoutineExerciseDropDelegate: DropDelegate {
    let exercise: NewRoutineExerciseDraft
    @Binding var exercises: [NewRoutineExerciseDraft]
    @Binding var draggedExerciseID: UUID?

    func dropEntered(info: DropInfo) {
        guard let draggedExerciseID,
              draggedExerciseID != exercise.id,
              let fromIndex = exercises.firstIndex(where: { $0.id == draggedExerciseID }),
              let toIndex = exercises.firstIndex(where: { $0.id == exercise.id })
        else {
            return
        }

        withAnimation(.snappy) {
            exercises.move(
                fromOffsets: IndexSet(integer: fromIndex),
                toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
            )
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedExerciseID = nil
        return true
    }
}

#Preview {
    NewRoutineView()
}
