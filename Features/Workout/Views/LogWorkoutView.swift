//
//  LogWorkoutView.swift
//  GymBud
//
//  Created by Codex on 03/05/26.
//

import Combine
import SwiftUI
import UniformTypeIdentifiers

struct LogWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var exercises: [LogWorkoutExerciseDraft]
    @State private var currentExerciseIndex = 0
    @State private var previousWorkout: WorkoutLog?
    @State private var elapsedSeconds = 0
    @State private var draggedExerciseID: UUID?
    @State private var errorMessage: String?
    @State private var isLoadingPrevious = false
    @State private var isCompletingWorkout = false
    @State private var isShowingCompleteWorkout = false
    @State private var isShowingSkipConfirmation = false
    @State private var isShowingExerciseTransition = false
    @State private var nextExerciseCountdown = 15
    @State private var transitionTask: Task<Void, Never>?
    @State private var skippedExerciseIDs: Set<String> = []
    private let routine: Routine
    private let workoutService: any WorkoutServiceProtocol
    private let startedAt = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(
        routine: Routine,
        workoutService: any WorkoutServiceProtocol = WorkoutService()
    ) {
        self.routine = routine
        self.workoutService = workoutService
        _exercises = State(initialValue: routine.exercises
            .sorted { $0.orderIndex < $1.orderIndex }
            .map(LogWorkoutExerciseDraft.init(routineExercise:)))
    }

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    workoutStats
                    currentExerciseContent
                    setActions
                    upNextSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 104)
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom) {
            bottomActionBar
        }
        .task {
            await loadPreviousWorkout()
        }
        .onReceive(timer) { date in
            elapsedSeconds = max(0, Int(date.timeIntervalSince(startedAt)))
        }
        .alert("Skip Exercise?", isPresented: $isShowingSkipConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Skip", role: .destructive) {
                skipCurrentExercise()
            }
        } message: {
            Text("This exercise will be removed from your workout log.")
        }
        .alert("Well done!", isPresented: $isShowingExerciseTransition) {
            Button("Skip Wait") {
                startPendingExercise()
            }
        } message: {
            Text("New exercise starting in \(nextExerciseCountdown) seconds.")
        }
        .fullScreenCover(isPresented: $isShowingCompleteWorkout) {
            CompleteWorkoutPlaceholderView()
        }
        .onDisappear {
            transitionTask?.cancel()
        }
    }

    private var bottomActionBar: some View {
        VStack(spacing: 10) {
            if let errorMessage {
                Text(errorMessage)
                    .font(AppFonts.Body.bold(12))
                    .foregroundStyle(AppColors.error)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            GBPrimaryButton(
                title: primaryActionTitle,
                isLoading: isCompletingWorkout,
                isDisabled: exercises.isEmpty
            ) {
                finishCurrentExercise()
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(AppColors.background.opacity(0.92))
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close workout")

            Spacer()

            Text(routine.name)
                .font(AppFonts.Body.bold(13))
                .foregroundStyle(AppColors.onSurfaceVariant)
                .lineLimit(1)

            Spacer()

            Color.clear
                .frame(width: 34, height: 34)
        }
    }

    private var workoutStats: some View {
        HStack(spacing: 14) {
            LogWorkoutStatCard(title: "VOLUME", value: formattedVolume, detail: "KG")
            LogWorkoutStatCard(title: "TIME", value: formattedElapsedTime, detail: nil, isHighlighted: true)
            LogWorkoutStatCard(title: "SETS", value: "\(completedSetCount)", detail: "/ \(totalSetCount)")
        }
    }

    @ViewBuilder
    private var currentExerciseContent: some View {
        if exercises.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("CURRENTLY TRACKING")
                    .font(AppFonts.Body.bold(11))
                    .tracking(1.4)
                    .foregroundStyle(AppColors.secondary)

                Text("No exercises in this routine")
                    .font(AppFonts.Headline.bold(28))
                    .foregroundStyle(AppColors.onBackground)
            }
        } else {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text("CURRENTLY TRACKING")
                            .font(AppFonts.Body.bold(11))
                            .tracking(1.4)
                            .foregroundStyle(AppColors.secondary)

                        Spacer(minLength: 12)

                        skipButton
                    }

                    Text(currentExercise.name)
                        .font(AppFonts.Headline.bold(31))
                        .foregroundStyle(AppColors.onBackground)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }

                VStack(spacing: 12) {
                    ForEach(currentExercise.sets.indices, id: \.self) { setIndex in
                        LogWorkoutSetCard(
                            set: $exercises[currentExerciseIndex].sets[setIndex],
                            previousSet: previousSet(
                                exerciseID: currentExercise.exerciseID,
                                setNumber: exercises[currentExerciseIndex].sets[setIndex].setNumber
                            )
                        ) {
                            exercises[currentExerciseIndex].sets[setIndex].hasUserEdited = true
                        } onToggleLog: {
                            exercises[currentExerciseIndex].sets[setIndex].isCompleted.toggle()
                        }
                    }
                }
            }
        }
    }

    private var setActions: some View {
        HStack(spacing: 12) {
            addSetButton
            removeLastSetButton
        }
    }

    private var addSetButton: some View {
        setActionButton(
            title: "ADD SET",
            systemImage: "plus.circle",
            isDisabled: exercises.isEmpty
        ) {
            guard !exercises.isEmpty else { return }
            exercises[currentExerciseIndex].sets.append(exercises[currentExerciseIndex].nextSet)
        }
    }

    private var removeLastSetButton: some View {
        setActionButton(
            title: "REMOVE LAST",
            systemImage: "minus.circle",
            isDestructive: true,
            isDisabled: !canRemoveLastSet
        ) {
            removeLastSet()
        }
    }

    private func setActionButton(
        title: String,
        systemImage: String,
        isDestructive: Bool = false,
        isDisabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .bold))

                Text(title)
                    .font(AppFonts.Body.bold(11))
                    .tracking(1.4)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .foregroundStyle(isDestructive ? AppColors.error : AppColors.onSurfaceVariant)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(
                        (isDestructive ? AppColors.error : AppColors.outlineVariant).opacity(isDestructive ? 0.45 : 0.9),
                        style: StrokeStyle(lineWidth: 1.2, dash: [3, 4])
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.55 : 1)
    }

    @ViewBuilder
    private var upNextSection: some View {
        if !upNextExercises.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("UP NEXT")
                    .font(AppFonts.Body.bold(11))
                    .tracking(1.3)
                    .foregroundStyle(AppColors.onSurfaceVariant)

                VStack(spacing: 10) {
                    ForEach(upNextExercises) { exercise in
                        LogWorkoutUpNextCard(exercise: exercise)
                            .onDrag {
                                draggedExerciseID = exercise.id
                                return NSItemProvider(object: exercise.id.uuidString as NSString)
                            }
                            .onDrop(
                                of: [.text],
                                delegate: LogWorkoutExerciseDropDelegate(
                                    exercise: exercise,
                                    lockedUpperBound: currentExerciseIndex,
                                    exercises: $exercises,
                                    draggedExerciseID: $draggedExerciseID
                                )
                            )
                    }
                }
            }
        }
    }

    private var skipButton: some View {
        Button {
            isShowingSkipConfirmation = true
        } label: {
            Text("SKIP")
                .font(AppFonts.Body.bold(12))
                .tracking(1.4)
                .foregroundStyle(AppColors.error)
                .padding(.horizontal, 14)
                .frame(height: 34)
                .background(AppColors.error.opacity(0.1))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(exercises.isEmpty || isCompletingWorkout)
        .opacity(exercises.isEmpty || isCompletingWorkout ? 0.6 : 1)
    }

    private var currentExercise: LogWorkoutExerciseDraft {
        exercises[currentExerciseIndex]
    }

    private var upNextExercises: [LogWorkoutExerciseDraft] {
        guard currentExerciseIndex + 1 < exercises.count else { return [] }
        return Array(exercises[(currentExerciseIndex + 1)...])
    }

    private var primaryActionTitle: String {
        currentExerciseIndex == exercises.count - 1 ? "COMPLETE WORKOUT" : "FINISH EXERCISE"
    }

    private var completedSetCount: Int {
        exercises.flatMap(\.sets).filter(\.isCompleted).count
    }

    private var totalSetCount: Int {
        exercises.flatMap(\.sets).count
    }

    private var canRemoveLastSet: Bool {
        !exercises.isEmpty && exercises[currentExerciseIndex].sets.count > 1
    }

    private var formattedVolume: String {
        let volume = exercises
            .flatMap(\.sets)
            .filter(\.isCompleted)
            .reduce(0) { $0 + Double($1.effectiveReps) * $1.effectiveWeightKG }

        return volume.formatted(.number.precision(.fractionLength(volume.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 1)))
    }

    private var formattedElapsedTime: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }

    private func previousSet(exerciseID: String, setNumber: Int) -> WorkoutSetLog? {
        previousWorkout?.exercises
            .first { $0.exerciseID == exerciseID }?
            .sets
            .first { $0.setNumber == setNumber && $0.actualReps != nil && $0.actualWeightKG != nil }
    }

    private func removeLastSet() {
        guard canRemoveLastSet else { return }
        exercises[currentExerciseIndex].sets.removeLast()
    }

    private func finishCurrentExercise() {
        guard !exercises.isEmpty, !isCompletingWorkout else { return }
        transitionTask?.cancel()

        for index in exercises[currentExerciseIndex].sets.indices {
            exercises[currentExerciseIndex].sets[index].isCompleted = true
        }

        if currentExerciseIndex < exercises.count - 1 {
            showExerciseTransition()
            return
        }

        completeWorkout()
    }

    private func skipCurrentExercise() {
        guard !exercises.isEmpty, !isCompletingWorkout else { return }
        transitionTask?.cancel()
        isShowingExerciseTransition = false

        skippedExerciseIDs.insert(exercises[currentExerciseIndex].exerciseID)
        exercises.remove(at: currentExerciseIndex)

        guard !exercises.isEmpty else {
            completeWorkout()
            return
        }

        currentExerciseIndex = min(currentExerciseIndex, exercises.count - 1)
    }

    private func showExerciseTransition() {
        nextExerciseCountdown = 15
        isShowingExerciseTransition = true
        transitionTask = Task {
            for secondsRemaining in stride(from: 14, through: 0, by: -1) {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    nextExerciseCountdown = secondsRemaining
                }
            }

            await MainActor.run {
                startPendingExercise()
            }
        }
    }

    private func startPendingExercise() {
        transitionTask?.cancel()
        transitionTask = nil
        isShowingExerciseTransition = false

        guard !exercises.isEmpty, currentExerciseIndex < exercises.count - 1 else { return }
        currentExerciseIndex += 1
    }

    private func completeWorkout() {
        guard let accessToken = workoutService.storedAccessToken(),
              !accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            errorMessage = "Please log in again to complete this workout."
            return
        }

        isCompletingWorkout = true
        errorMessage = nil

        let request = CompleteWorkoutRequest(
            routineID: routine.id,
            startTime: Self.isoString(from: startedAt),
            endTime: Self.isoString(from: Date()),
            visibility: "all",
            exercises: exercises
                .filter { !skippedExerciseIDs.contains($0.exerciseID) }
                .map { exercise in
                CompleteWorkoutExerciseRequest(
                    exerciseID: exercise.exerciseID,
                    sets: exercise.sets.map { set in
                        CompleteWorkoutSetRequest(
                            setNumber: set.setNumber,
                            actualReps: set.effectiveReps,
                            actualWeightKG: set.effectiveWeightKG
                        )
                    }
                )
            }
        )

        Task {
            do {
                _ = try await workoutService.completeWorkout(request, accessToken: accessToken)
                isShowingCompleteWorkout = true
            } catch {
                errorMessage = "Unable to complete workout."
            }

            isCompletingWorkout = false
        }
    }

    private func loadPreviousWorkout() async {
        guard let accessToken = workoutService.storedAccessToken(),
              !accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return
        }

        isLoadingPrevious = true
        previousWorkout = try? await workoutService.latestWorkout(routineID: routine.id, accessToken: accessToken)
        if let previousWorkout {
            prefillExercises(from: previousWorkout)
        }
        isLoadingPrevious = false
    }

    private func prefillExercises(from workout: WorkoutLog) {
        for exerciseIndex in exercises.indices {
            guard let previousExercise = workout.exercises.first(where: { $0.exerciseID == exercises[exerciseIndex].exerciseID }) else {
                continue
            }

            let previousSets = previousExercise.sets
                .filter { $0.actualReps != nil || $0.actualWeightKG != nil }
                .sorted { $0.setNumber < $1.setNumber }

            guard !previousSets.isEmpty else { continue }

            while exercises[exerciseIndex].sets.count < previousSets.count {
                exercises[exerciseIndex].sets.append(exercises[exerciseIndex].nextSet)
            }

            for previousSet in previousSets {
                guard let setIndex = exercises[exerciseIndex].sets.firstIndex(where: { $0.setNumber == previousSet.setNumber }) else {
                    continue
                }

                exercises[exerciseIndex].sets[setIndex].applyPreviousWorkoutHints(from: previousSet)
            }
        }
    }

    nonisolated private static func isoString(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }
}

private struct LogWorkoutStatCard: View {
    let title: String
    let value: String
    let detail: String?
    var isHighlighted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFonts.Body.bold(9))
                .tracking(1.1)
                .foregroundStyle(AppColors.onSurfaceVariant)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(AppFonts.Headline.bold(23))
                    .foregroundStyle(isHighlighted ? AppColors.secondary : AppColors.onBackground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                if let detail {
                    Text(detail)
                        .font(AppFonts.Body.bold(9))
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 80)
        .background(Color.black.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct LogWorkoutSetCard: View {
    @Binding var set: LogWorkoutSetDraft
    let previousSet: WorkoutSetLog?
    let onBeginEditing: () -> Void
    let onToggleLog: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text("\(set.setNumber)")
                .font(AppFonts.Body.bold(15))
                .foregroundStyle(set.isCompleted ? AppColors.onSurfaceVariant : AppColors.primaryFixed)
                .frame(width: 28, height: 28)
                .background(AppColors.surface.opacity(0.7))
                .clipShape(Circle())

            LogWorkoutValueField(
                text: $set.actualWeightText,
                placeholder: set.weightPlaceholderText,
                suffix: "KG",
                isDisabled: set.isCompleted,
                onBeginEditing: onBeginEditing
            )
            LogWorkoutIntField(
                text: $set.actualRepsText,
                placeholder: set.repsPlaceholderText,
                suffix: "REPS",
                isDisabled: set.isCompleted,
                onBeginEditing: onBeginEditing
            )

            Spacer(minLength: 4)

            if let previousText {
                Text(previousText)
                    .font(AppFonts.Body.bold(9))
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .lineLimit(2)
                    .frame(width: 58, alignment: .leading)
            }

            if set.isCompleted {
                Button(action: onToggleLog) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.black.opacity(0.78))
                        .frame(width: 40, height: 40)
                        .background(AppColors.primaryFixed)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Unlog set \(set.setNumber)")
            } else {
                Button(action: onToggleLog) {
                    Text("LOG SET")
                        .font(AppFonts.Body.bold(10))
                        .foregroundStyle(Color.black.opacity(0.78))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(width: 64, height: 40)
                        .background(AppColors.primaryFixed)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 100)
        .background(set.isCompleted ? AppColors.surfaceVariant.opacity(0.62) : AppColors.surfaceBright.opacity(0.88))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(set.isCompleted ? Color.clear : AppColors.onBackground.opacity(0.88), lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var previousText: String? {
        guard let reps = previousSet?.actualReps,
              let weight = previousSet?.actualWeightKG
        else {
            return nil
        }

        let weightText = weight.formatted(.number.precision(.fractionLength(weight.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 1)))
        return "PREV: \(weightText) KG X \(reps)"
    }
}

private struct LogWorkoutValueField: View {
    @Binding var text: String
    let placeholder: String
    let suffix: String
    let isDisabled: Bool
    let onBeginEditing: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 3) {
            TextField(
                "",
                text: $text,
                prompt: Text(placeholder).foregroundStyle(AppColors.onSurfaceVariant.opacity(0.72))
            )
                .font(AppFonts.Headline.bold(22))
                .foregroundStyle(AppColors.onBackground)
                .multilineTextAlignment(.center)
                .keyboardType(.decimalPad)
                .focused($isFocused)
                .disabled(isDisabled)
                .onChange(of: text) { _, _ in
                    onBeginEditing()
                }
                .onChange(of: isFocused) { _, isFocused in
                    guard isFocused else { return }
                    onBeginEditing()
                }

            Text(suffix)
                .font(AppFonts.Body.bold(9))
                .foregroundStyle(AppColors.onSurfaceVariant)
        }
        .frame(width: 64, height: 62)
        .background(isDisabled ? AppColors.surfaceVariant.opacity(0.32) : AppColors.surface.opacity(0.56))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .contentShape(Rectangle())
        .opacity(isDisabled ? 0.7 : 1)
    }
}

private struct LogWorkoutIntField: View {
    @Binding var text: String
    let placeholder: String
    let suffix: String
    let isDisabled: Bool
    let onBeginEditing: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 3) {
            TextField(
                "",
                text: $text,
                prompt: Text(placeholder).foregroundStyle(AppColors.onSurfaceVariant.opacity(0.72))
            )
                .font(AppFonts.Headline.bold(22))
                .foregroundStyle(AppColors.secondary)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .focused($isFocused)
                .disabled(isDisabled)
                .onChange(of: text) { _, _ in
                    onBeginEditing()
                }
                .onChange(of: isFocused) { _, isFocused in
                    guard isFocused else { return }
                    onBeginEditing()
                }

            Text(suffix)
                .font(AppFonts.Body.bold(9))
                .foregroundStyle(AppColors.onSurfaceVariant)
        }
        .frame(width: 62, height: 62)
        .background(isDisabled ? AppColors.surfaceVariant.opacity(0.32) : AppColors.surface.opacity(0.56))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .contentShape(Rectangle())
        .opacity(isDisabled ? 0.7 : 1)
    }
}

private struct LogWorkoutUpNextCard: View {
    let exercise: LogWorkoutExerciseDraft

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(AppColors.surfaceBright)

                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppColors.onSurfaceVariant)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(AppFonts.Body.bold(15))
                    .foregroundStyle(AppColors.onBackground)
                    .lineLimit(1)

                Text("\(exercise.sets.count) Sets • \(exercise.repRangeText)")
                    .font(AppFonts.Body.medium(12))
                    .foregroundStyle(AppColors.onSurfaceVariant)
            }

            Spacer()

            Image(systemName: "line.3.horizontal")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.onSurfaceVariant)
                .frame(width: 28, height: 28)
        }
        .padding(.horizontal, 14)
        .frame(height: 78)
        .background(Color.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct CompleteWorkoutPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topLeading) {
            AppColors.background
                .ignoresSafeArea()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .padding(.top, 14)
            .padding(.leading, 20)
            .accessibilityLabel("Close complete workout")
        }
    }
}

private struct LogWorkoutExerciseDraft: Identifiable {
    let id = UUID()
    let exerciseID: String
    let name: String
    var sets: [LogWorkoutSetDraft]

    nonisolated init(routineExercise: RoutineExercise) {
        exerciseID = routineExercise.exerciseID
        name = routineExercise.exercise.name
        let orderedSets = routineExercise.sets.sorted { $0.setNumber < $1.setNumber }
        sets = orderedSets.isEmpty
            ? [LogWorkoutSetDraft(setNumber: 1, plannedMinReps: 8, plannedMaxReps: 10, plannedWeightKG: 0)]
            : orderedSets.map { set in
                LogWorkoutSetDraft(
                    setNumber: set.setNumber,
                    plannedMinReps: set.minReps,
                    plannedMaxReps: set.maxReps,
                    plannedWeightKG: set.targetWeightKG
                )
            }
    }

    var nextSet: LogWorkoutSetDraft {
        let previous = sets.last ?? LogWorkoutSetDraft(setNumber: 0, plannedMinReps: 8, plannedMaxReps: 10, plannedWeightKG: 0)
        return LogWorkoutSetDraft(
            setNumber: sets.count + 1,
            plannedMinReps: previous.plannedMinReps,
            plannedMaxReps: previous.plannedMaxReps,
            plannedWeightKG: previous.plannedWeightKG
        )
    }

    var repRangeText: String {
        guard let firstSet = sets.first else { return "0 Reps" }
        return "\(firstSet.plannedMinReps)-\(firstSet.plannedMaxReps) Reps"
    }
}

private struct LogWorkoutSetDraft: Identifiable {
    let id = UUID()
    let setNumber: Int
    let plannedMinReps: Int
    let plannedMaxReps: Int
    let plannedWeightKG: Double
    var actualRepsText = ""
    var actualWeightText = ""
    var repsPlaceholderText: String
    var weightPlaceholderText: String
    var isCompleted = false
    var hasUserEdited = false

    nonisolated init(
        setNumber: Int,
        plannedMinReps: Int,
        plannedMaxReps: Int,
        plannedWeightKG: Double
    ) {
        self.setNumber = setNumber
        self.plannedMinReps = plannedMinReps
        self.plannedMaxReps = plannedMaxReps
        self.plannedWeightKG = plannedWeightKG
        repsPlaceholderText = "\(plannedMaxReps)"
        weightPlaceholderText = Self.formattedWeight(plannedWeightKG)
    }

    var effectiveReps: Int {
        if let reps = Int(actualRepsText.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return reps
        }

        if !hasUserEdited,
           let placeholderReps = Int(repsPlaceholderText.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return placeholderReps
        }

        return 0
    }

    var effectiveWeightKG: Double {
        if let weight = Double(actualWeightText.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return weight
        }

        if !hasUserEdited,
           let placeholderWeight = Double(weightPlaceholderText.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return placeholderWeight
        }

        return 0
    }

    mutating func applyPreviousWorkoutHints(from previousSet: WorkoutSetLog) {
        guard !isCompleted else { return }

        if let actualReps = previousSet.actualReps {
            repsPlaceholderText = "\(actualReps)"
        }

        if let actualWeightKG = previousSet.actualWeightKG {
            weightPlaceholderText = Self.formattedWeight(actualWeightKG)
        }
    }

    nonisolated private static func formattedWeight(_ weight: Double) -> String {
        weight.formatted(.number.precision(.fractionLength(weight.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 1)))
    }
}

private struct LogWorkoutExerciseDropDelegate: DropDelegate {
    let exercise: LogWorkoutExerciseDraft
    let lockedUpperBound: Int
    @Binding var exercises: [LogWorkoutExerciseDraft]
    @Binding var draggedExerciseID: UUID?

    func dropEntered(info: DropInfo) {
        guard let draggedExerciseID,
              draggedExerciseID != exercise.id,
              let fromIndex = exercises.firstIndex(where: { $0.id == draggedExerciseID }),
              let toIndex = exercises.firstIndex(where: { $0.id == exercise.id }),
              fromIndex > lockedUpperBound,
              toIndex > lockedUpperBound
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
    LogWorkoutView(routine: .sample(id: "routine-1", name: "Push Day", exerciseCount: 4))
}
