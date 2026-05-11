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
    @Environment(\.scenePhase) private var scenePhase
    @State private var exercises: [LogWorkoutExerciseDraft]
    @State private var currentExerciseIndex = 0
    @State private var previousWorkout: WorkoutLog?
    @State private var elapsedSeconds = 0
    @State private var draggedExerciseID: UUID?
    @State private var errorMessage: String?
    @State private var isLoadingPrevious = false
    @State private var isCompletingWorkout = false
    @State private var didCompleteWorkout = false
    @State private var completedWorkout: WorkoutLog?
    @State private var isShowingSkipConfirmation = false
    @State private var isShowingRoutineUpdateConfirmation = false
    @State private var replacingExerciseIndex: Int?
    @State private var skippedExerciseIDs: Set<String> = []
    @State private var hasReplacedExercises = false
    private let routine: Routine
    private let workoutService: any WorkoutServiceProtocol
    private let routineService: any RoutineServiceProtocol
    private let progressStore: any ActiveWorkoutProgressStoreProtocol
    private let startedAt: Date
    private let shouldLoadPreviousWorkout: Bool
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(
        routine: Routine,
        activeProgress: ActiveWorkoutProgress? = nil,
        progressStore: any ActiveWorkoutProgressStoreProtocol = ActiveWorkoutProgressStore.shared,
        workoutService: any WorkoutServiceProtocol = WorkoutService(),
        routineService: any RoutineServiceProtocol = RoutineService()
    ) {
        self.routine = routine
        self.progressStore = progressStore
        self.workoutService = workoutService
        self.routineService = routineService
        if let activeProgress, activeProgress.routineID == routine.id {
            startedAt = activeProgress.startedAt
            shouldLoadPreviousWorkout = false
            _elapsedSeconds = State(initialValue: max(0, activeProgress.cachedElapsedSeconds))
            _currentExerciseIndex = State(initialValue: min(activeProgress.currentExerciseIndex, max(activeProgress.exercises.count - 1, 0)))
            _skippedExerciseIDs = State(initialValue: activeProgress.skippedExerciseIDs)
            _hasReplacedExercises = State(initialValue: activeProgress.hasReplacedExercises)
            _exercises = State(initialValue: activeProgress.exercises.map(LogWorkoutExerciseDraft.init(progress:)))
        } else {
            startedAt = Date()
            shouldLoadPreviousWorkout = true
            _elapsedSeconds = State(initialValue: 0)
            _exercises = State(initialValue: routine.exercises
                .sorted { $0.orderIndex < $1.orderIndex }
                .map(LogWorkoutExerciseDraft.init(routineExercise:)))
        }
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
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 104)
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom) {
            bottomActionBar
        }
        .task {
            if shouldLoadPreviousWorkout {
                await loadPreviousWorkout()
            }
        }
        .onReceive(timer) { _ in
            incrementElapsedSeconds()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                cacheCurrentProgress()
            }
        }
        .onDisappear {
            cacheCurrentProgress()
        }
        .alert("Skip Exercise?", isPresented: $isShowingSkipConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Skip", role: .destructive) {
                skipCurrentExercise()
            }
        } message: {
            Text("This exercise will be removed from your workout log.")
        }
        .alert("Update Routine?", isPresented: $isShowingRoutineUpdateConfirmation) {
            Button("No") {
                completeWorkout(updateRoutineFirst: false)
            }
            Button("Yes") {
                completeWorkout(updateRoutineFirst: true)
            }
        } message: {
            Text("You replaced one or more exercises. Do you want to update this routine before saving the workout?")
        }
        .fullScreenCover(item: $completedWorkout) { workout in
            CompleteWorkoutSummaryView(workout: workout, routine: routine) {
                completedWorkout = nil
                dismiss()
            }
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { replacingExerciseIndex != nil },
                set: { isPresented in
                    if !isPresented {
                        replacingExerciseIndex = nil
                    }
                }
            )
        ) {
            exerciseReplacementView
        }
    }

    private var bottomActionBar: some View {
        VStack(spacing: 10) {
            if let errorMessage {
                Text(errorMessage)
                    .font(AppFonts.Body.bold(12))
                    .foregroundStyle(AppColors.error)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }

            GBPrimaryButton(
                title: primaryActionTitle,
                isLoading: isCompletingWorkout,
                isDisabled: exercises.isEmpty
            ) {
                finishCurrentExercise()
            }
            .padding(.horizontal, 16)
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

                        HStack(spacing: 8) {
                            replaceButton(for: currentExerciseIndex)
                            skipButton
                        }
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
                            set: $exercises[currentExerciseIndex].sets[setIndex]
                        ) {
                            exercises[currentExerciseIndex].sets[setIndex].hasUserEdited = true
                        } onToggleLog: {
                            exercises[currentExerciseIndex].sets[setIndex].isCompleted.toggle()
                            cacheCurrentProgress()
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
            cacheCurrentProgress()
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
                    ForEach(Array(exercises.indices.dropFirst(currentExerciseIndex + 1)), id: \.self) { exerciseIndex in
                        LogWorkoutUpNextCard(
                            exercise: exercises[exerciseIndex],
                            canReplace: canReplaceExercise(at: exerciseIndex)
                        ) {
                            beginReplacingExercise(at: exerciseIndex)
                        }
                            .onDrag {
                                draggedExerciseID = exercises[exerciseIndex].id
                                return NSItemProvider(object: exercises[exerciseIndex].id.uuidString as NSString)
                            }
                            .onDrop(
                                of: [.text],
                                delegate: LogWorkoutExerciseDropDelegate(
                                    exercise: exercises[exerciseIndex],
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
                .padding(.horizontal, 16)
                .frame(height: 34)
                .background(AppColors.error.opacity(0.1))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(exercises.isEmpty || isCompletingWorkout)
        .opacity(exercises.isEmpty || isCompletingWorkout ? 0.6 : 1)
    }

    private func replaceButton(for exerciseIndex: Int) -> some View {
        let canReplace = canReplaceExercise(at: exerciseIndex)

        return Button {
            beginReplacingExercise(at: exerciseIndex)
        } label: {
            Text("REPLACE")
                .font(AppFonts.Body.bold(12))
                .tracking(1.4)
                .foregroundStyle(canReplace ? AppColors.primary : AppColors.onSurfaceVariant.opacity(0.7))
                .padding(.horizontal, 16)
                .frame(height: 34)
                .background(canReplace ? AppColors.primary.opacity(0.12) : AppColors.surfaceBright.opacity(0.42))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!canReplace || isCompletingWorkout)
        .opacity(!canReplace || isCompletingWorkout ? 0.55 : 1)
    }

    @ViewBuilder
    private var exerciseReplacementView: some View {
        if let replacingExerciseIndex,
           exercises.indices.contains(replacingExerciseIndex) {
            ExercisesView(
                selectedExercises: [exercises[replacingExerciseIndex].exerciseSelection],
                selectionLimit: 1,
                onCancel: {
                    self.replacingExerciseIndex = nil
                },
                onSave: { selectedExercises in
                    guard let selectedExercise = selectedExercises.first else { return }
                    replaceExercise(at: replacingExerciseIndex, with: selectedExercise)
                    self.replacingExerciseIndex = nil
                }
            )
        }
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
            .reduce(0) { total, exercise in
                total + exercise.sets
                    .filter(\.isCompleted)
                    .reduce(0) { setTotal, set in
                        setTotal + Double(set.effectiveReps) * set.effectiveWeightKG * exercise.volumeMultiplier
                    }
            }

        return volume.formatted(.number.precision(.fractionLength(volume.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 1)))
    }

    private var formattedElapsedTime: String {
        if elapsedSeconds >= 3600 {
            let hours = elapsedSeconds / 3600
            let minutes = (elapsedSeconds % 3600) / 60
            return "\(hours)h \(minutes)m"
        }

        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }

    private func removeLastSet() {
        guard canRemoveLastSet else { return }
        exercises[currentExerciseIndex].sets.removeLast()
        cacheCurrentProgress()
    }

    private func finishCurrentExercise() {
        guard !exercises.isEmpty, !isCompletingWorkout else { return }

        for index in exercises[currentExerciseIndex].sets.indices {
            exercises[currentExerciseIndex].sets[index].isCompleted = true
        }

        if currentExerciseIndex < exercises.count - 1 {
            currentExerciseIndex += 1
            cacheCurrentProgress()
            return
        }

        cacheCurrentProgress()
        requestWorkoutCompletion()
    }

    private func skipCurrentExercise() {
        guard !exercises.isEmpty, !isCompletingWorkout else { return }

        skippedExerciseIDs.insert(exercises[currentExerciseIndex].exerciseID)
        exercises.remove(at: currentExerciseIndex)

        guard !exercises.isEmpty else {
            cacheCurrentProgress()
            requestWorkoutCompletion()
            return
        }

        currentExerciseIndex = min(currentExerciseIndex, exercises.count - 1)
        cacheCurrentProgress()
    }

    private func canReplaceExercise(at index: Int) -> Bool {
        guard exercises.indices.contains(index) else { return false }
        return !exercises[index].sets.contains { $0.isCompleted }
    }

    private func beginReplacingExercise(at index: Int) {
        guard canReplaceExercise(at: index), !isCompletingWorkout else { return }
        replacingExerciseIndex = index
    }

    private func replaceExercise(at index: Int, with exercise: Exercise) {
        guard canReplaceExercise(at: index) else { return }
        exercises[index].replace(with: exercise)
        hasReplacedExercises = true
        cacheCurrentProgress()
    }

    private func incrementElapsedSeconds() {
        guard scenePhase == .active, !didCompleteWorkout else { return }
        elapsedSeconds += 1
    }

    private func cacheCurrentProgress() {
        guard !didCompleteWorkout else { return }

        guard !exercises.isEmpty else {
            progressStore.clear()
            return
        }

        guard exercises.flatMap(\.sets).contains(where: \.isCompleted) else {
            progressStore.clear()
            return
        }

        progressStore.save(
            ActiveWorkoutProgress(
                routineID: routine.id,
                routineName: routine.name,
                startedAt: startedAt,
                currentExerciseIndex: min(currentExerciseIndex, max(exercises.count - 1, 0)),
                skippedExerciseIDs: skippedExerciseIDs,
                exercises: exercises.map(\.progressSnapshot),
                cachedElapsedSeconds: elapsedSeconds,
                hasReplacedExercises: hasReplacedExercises,
                updatedAt: Date()
            )
        )
    }

    private func requestWorkoutCompletion() {
        if hasReplacedExercises {
            isShowingRoutineUpdateConfirmation = true
        } else {
            completeWorkout(updateRoutineFirst: false)
        }
    }

    private func completeWorkout(updateRoutineFirst: Bool) {
        guard let accessToken = workoutService.storedAccessToken(),
              !accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            errorMessage = "Please log in again to complete this workout."
            return
        }

        isCompletingWorkout = true
        errorMessage = nil

        let includedExercises = exercises.filter { !skippedExerciseIDs.contains($0.exerciseID) }

        let timerEndDate = startedAt.addingTimeInterval(TimeInterval(max(0, elapsedSeconds)))
        let request = CompleteWorkoutRequest(
            routineID: routine.id,
            startTime: Self.isoString(from: startedAt),
            endTime: Self.isoString(from: timerEndDate),
            visibility: "all",
            exercises: includedExercises.map { exercise in
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
                if updateRoutineFirst {
                    let routineRequest = makeRoutineUpdateRequest()
                    _ = try await routineService.updateRoutine(id: routine.id, request: routineRequest, accessToken: accessToken)
                }

                let workout = try await workoutService.completeWorkout(request, accessToken: accessToken)
                didCompleteWorkout = true
                progressStore.clear()
                completedWorkout = workout
                AppDataRefreshCenter.notifyChange(.workoutCompleted, userInfo: ["workoutID": workout.id])
            } catch {
                errorMessage = "Unable to complete workout."
            }

            isCompletingWorkout = false
        }
    }

    private func makeRoutineUpdateRequest() -> CreateRoutineRequest {
        CreateRoutineRequest(
            name: routine.name,
            exercises: exercises.map { exercise in
                CreateRoutineExerciseRequest(
                    exerciseID: exercise.exerciseID,
                    orderIndex: exercise.orderIndex,
                    sets: exercise.sets.map { set in
                        CreateRoutineSetRequest(
                            setNumber: set.setNumber,
                            minReps: set.plannedMinReps,
                            maxReps: set.plannedMaxReps,
                            targetWeightKG: set.plannedWeightKG
                        )
                    }
                )
            }
        )
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
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 80)
        .background(Color.black.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct LogWorkoutSetCard: View {
    @Binding var set: LogWorkoutSetDraft
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
        .padding(.horizontal, 16)
        .frame(height: 100)
        .background(set.isCompleted ? AppColors.surfaceVariant.opacity(0.62) : AppColors.surfaceBright.opacity(0.88))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(set.isCompleted ? Color.clear : AppColors.onBackground.opacity(0.88), lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
    let canReplace: Bool
    let onReplace: () -> Void

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

            Button(action: onReplace) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(canReplace ? AppColors.primary : AppColors.onSurfaceVariant.opacity(0.62))
                    .frame(width: 32, height: 32)
                    .background((canReplace ? AppColors.primary : AppColors.surfaceBright).opacity(canReplace ? 0.12 : 0.42))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(!canReplace)
            .accessibilityLabel("Replace \(exercise.name)")

            Image(systemName: "line.3.horizontal")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.onSurfaceVariant)
                .frame(width: 28, height: 28)
        }
        .padding(.horizontal, 16)
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
            .padding(.leading, 16)
            .accessibilityLabel("Close complete workout")
        }
    }
}

private struct LogWorkoutExerciseDraft: Identifiable {
    let id = UUID()
    var exerciseID: String
    var orderIndex: Int
    var name: String
    var movementMethod: String?
    var equipment: String?
    var primaryMuscle: String?
    var secondaryMuscles: [String]
    var difficulty: String?
    var sets: [LogWorkoutSetDraft]

    nonisolated init(routineExercise: RoutineExercise) {
        exerciseID = routineExercise.exerciseID
        orderIndex = routineExercise.orderIndex
        name = routineExercise.exercise.name
        movementMethod = routineExercise.exercise.movementMode
        equipment = routineExercise.exercise.equipment
        primaryMuscle = routineExercise.exercise.primaryMuscle
        secondaryMuscles = routineExercise.exercise.secondaryMuscles
        difficulty = routineExercise.exercise.difficulty
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

    nonisolated init(progress: ActiveWorkoutExerciseProgress) {
        exerciseID = progress.exerciseID
        orderIndex = progress.orderIndex
        name = progress.name
        movementMethod = progress.movementMethod
        equipment = progress.equipment
        primaryMuscle = progress.primaryMuscle
        secondaryMuscles = progress.secondaryMuscles
        difficulty = progress.difficulty
        sets = progress.sets.map(LogWorkoutSetDraft.init(progress:))
    }

    var progressSnapshot: ActiveWorkoutExerciseProgress {
        ActiveWorkoutExerciseProgress(
            exerciseID: exerciseID,
            orderIndex: orderIndex,
            name: name,
            movementMethod: movementMethod,
            equipment: equipment,
            primaryMuscle: primaryMuscle,
            secondaryMuscles: secondaryMuscles,
            difficulty: difficulty,
            sets: sets.map(\.progressSnapshot)
        )
    }

    var exerciseSelection: Exercise {
        Exercise(
            id: exerciseID,
            name: name,
            equipment: equipment,
            primaryMuscle: primaryMuscle,
            secondaryMuscles: secondaryMuscles,
            difficulty: difficulty,
            movementMode: movementMethod
        )
    }

    mutating func replace(with exercise: Exercise) {
        exerciseID = exercise.id
        name = exercise.name
        movementMethod = exercise.movementMode
        equipment = exercise.equipment
        primaryMuscle = exercise.primaryMuscle
        secondaryMuscles = exercise.secondaryMuscles
        difficulty = exercise.difficulty
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

    var volumeMultiplier: Double {
        let isUnilateral = movementMethod?.caseInsensitiveCompare("unilateral") == .orderedSame
        let isDumbbell = equipment?.caseInsensitiveCompare("dumbbell") == .orderedSame
        return isUnilateral || isDumbbell ? 2 : 1
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

    nonisolated init(progress: ActiveWorkoutSetProgress) {
        setNumber = progress.setNumber
        plannedMinReps = progress.plannedMinReps
        plannedMaxReps = progress.plannedMaxReps
        plannedWeightKG = progress.plannedWeightKG
        actualRepsText = progress.actualRepsText
        actualWeightText = progress.actualWeightText
        repsPlaceholderText = progress.repsPlaceholderText
        weightPlaceholderText = progress.weightPlaceholderText
        isCompleted = progress.isCompleted
        hasUserEdited = progress.hasUserEdited
    }

    var progressSnapshot: ActiveWorkoutSetProgress {
        ActiveWorkoutSetProgress(
            setNumber: setNumber,
            plannedMinReps: plannedMinReps,
            plannedMaxReps: plannedMaxReps,
            plannedWeightKG: plannedWeightKG,
            actualRepsText: actualRepsText,
            actualWeightText: actualWeightText,
            repsPlaceholderText: repsPlaceholderText,
            weightPlaceholderText: weightPlaceholderText,
            isCompleted: isCompleted,
            hasUserEdited: hasUserEdited
        )
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
