//
//  WorkoutView.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import SwiftUI

struct WorkoutView: View {
    @State private var routines: [Routine] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedWorkoutLaunch: WorkoutLaunch?
    @State private var activeProgress: ActiveWorkoutProgress?
    @State private var didLoadInitialData: Bool
    private let routineService: any RoutineServiceProtocol = RoutineService()
    private let progressStore: any ActiveWorkoutProgressStoreProtocol = ActiveWorkoutProgressStore.shared

    init(initialRoutines: [Routine]? = nil, initialErrorMessage: String? = nil) {
        _routines = State(initialValue: RoutineListChangeStore.shared.filteredRoutines(initialRoutines ?? []))
        _errorMessage = State(initialValue: initialErrorMessage)
        _didLoadInitialData = State(initialValue: initialRoutines != nil || initialErrorMessage != nil)
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("LOG WORKOUT")
                            .font(AppFonts.Body.bold(12))
                            .tracking(1.6)
                            .foregroundStyle(AppColors.secondary)

                        Text("Choose a routine to start tracking.")
                            .font(AppFonts.Headline.bold(24))
                            .foregroundStyle(AppColors.onBackground)
                    }
                    .padding(.top, 26)

                    activeWorkoutSection
                    content
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 18)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height, alignment: .top)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.always)
            .refreshable {
                await loadRoutines()
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .onAppear {
            applyRoutineListChanges()
            activeProgress = progressStore.load()
        }
        .task {
            guard !didLoadInitialData else { return }
            didLoadInitialData = true
            await loadRoutines()
        }
        .fullScreenCover(item: $selectedWorkoutLaunch, onDismiss: {
            activeProgress = progressStore.load()
            selectedWorkoutLaunch = nil
        }) { launch in
            LogWorkoutView(
                routine: launch.routine,
                activeProgress: launch.activeProgress
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .routinesDidChange)) { notification in
            handleRoutinesDidChange(notification)
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && routines.isEmpty {
            ProgressView()
                .tint(AppColors.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 120)
        } else if let errorMessage {
            WorkoutMessageView(
                systemName: "exclamationmark.triangle",
                title: errorMessage,
                actionTitle: "TRY AGAIN"
            ) {
                Task {
                    await loadRoutines()
                }
            }
        } else if routines.isEmpty {
            WorkoutMessageView(
                systemName: "figure.strengthtraining.traditional",
                title: "No routines ready",
                actionTitle: nil,
                action: nil
            )
        } else {
            VStack(spacing: 14) {
                ForEach(routines) { routine in
                    Button {
                        startNewRoutine(routine)
                    } label: {
                        HStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(routine.name)
                                    .font(AppFonts.Headline.bold(21))
                                    .foregroundStyle(AppColors.onBackground)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)

                                Text("\(routine.exercises.count) EXERCISES")
                                    .font(AppFonts.Body.bold(11))
                                    .tracking(0.6)
                                    .foregroundStyle(AppColors.onSurfaceVariant)
                            }

                            Spacer()

                            Image(systemName: "play.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color.black.opacity(0.78))
                                .frame(width: 42, height: 42)
                                .background(AppColors.primaryFixed)
                                .clipShape(Circle())
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 92)
                        .background(AppColors.surfaceVariant.opacity(0.34))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var activeWorkoutSection: some View {
        if let activeProgress {
            ActiveWorkoutProgressCard(progress: activeProgress) {
                resumeActiveWorkout(activeProgress)
            }
        }
    }

    private func startNewRoutine(_ routine: Routine) {
        progressStore.clear()
        activeProgress = nil
        selectedWorkoutLaunch = WorkoutLaunch(routine: routine, activeProgress: nil)
    }

    private func resumeActiveWorkout(_ progress: ActiveWorkoutProgress) {
        let cachedProgress = progressStore.load() ?? progress
        let routine = routines.first(where: { $0.id == cachedProgress.routineID }) ?? cachedProgress.routineSnapshot
        selectedWorkoutLaunch = WorkoutLaunch(routine: routine, activeProgress: cachedProgress)
    }

    private func loadRoutines(preserveExistingData: Bool = false) async {
        guard !isLoading else { return }

        guard let accessToken = routineService.storedAccessToken(),
              !accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            errorMessage = "Please log in again to load routines."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let refreshedRoutines = try await routineService.routines(page: 1, accessToken: accessToken)
            routines = RoutineListChangeStore.shared.filteredRoutines(refreshedRoutines)
        } catch {
            if routines.isEmpty {
                errorMessage = "Unable to load routines."
            }
        }

        isLoading = false
        activeProgress = progressStore.load()
    }

    private func handleRoutinesDidChange(_ notification: Notification) {
        guard let deletedRoutineID = notification.userInfo?["deletedRoutineID"] as? String else {
            Task {
                await loadRoutines()
            }
            return
        }

        RoutineListChangeStore.shared.recordDeletedRoutineID(deletedRoutineID)
        applyRoutineListChanges()

        if activeProgress?.routineID == deletedRoutineID {
            progressStore.clear()
            activeProgress = nil
        }
    }

    private func applyRoutineListChanges() {
        routines = RoutineListChangeStore.shared.filteredRoutines(routines)
    }
}

private struct WorkoutLaunch: Identifiable {
    let id = UUID()
    let routine: Routine
    let activeProgress: ActiveWorkoutProgress?
}

private struct ActiveWorkoutProgressCard: View {
    let progress: ActiveWorkoutProgress
    let onResume: () -> Void

    private var progressFraction: Double {
        guard progress.totalExerciseCount > 0 else { return 0 }
        return min(1, max(0, Double(progress.completedExerciseCount) / Double(progress.totalExerciseCount)))
    }

    var body: some View {
        Button(action: onResume) {
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(AppColors.secondary)
                    .frame(width: 5)
                    .shadow(color: AppColors.secondary.opacity(0.55), radius: 8, x: 0, y: 0)

                VStack(alignment: .leading, spacing: 9) {
                    HStack(alignment: .center, spacing: 12) {
                        Text(progress.routineName.uppercased())
                            .font(AppFonts.Headline.bold(19).italic())
                            .foregroundStyle(AppColors.onBackground)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(AppColors.onSurfaceVariant)
                            .frame(width: 28, height: 28)
                    }

                    metricsRow(elapsedSeconds: progress.cachedElapsedSeconds)

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(AppColors.surfaceBright.opacity(0.75))

                            Capsule()
                                .fill(AppColors.secondary)
                                .frame(width: geometry.size.width * progressFraction)
                        }
                    }
                    .frame(height: 8)
                }
                .padding(.leading, 16)
                .padding(.trailing, 14)
            }
            .frame(height: 92)
            .background(AppColors.surfaceVariant.opacity(0.34))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Resume \(progress.routineName)")
    }

    private func estimatedElapsedTime(seconds elapsedSeconds: Int) -> String {
        let minutes = Int((Double(max(elapsedSeconds, 0)) / 60).rounded())

        if minutes < 1 {
            return "under 1 min"
        }

        if minutes < 56 {
            return "around \(minutes) \(minutes == 1 ? "min" : "mins")"
        }

        let hours = max(1, Int((Double(minutes) / 60).rounded()))
        return "around \(hours) \(hours == 1 ? "hour" : "hours")"
    }

    private func metricsRow(elapsedSeconds: Int) -> some View {
        HStack(spacing: 20) {
            ActiveWorkoutMetric(
                systemName: "timer",
                text: estimatedElapsedTime(seconds: elapsedSeconds),
                color: AppColors.secondary
            )

            ActiveWorkoutMetric(
                systemName: "checkmark.circle",
                text: "\(progress.completedExerciseCount)/\(progress.totalExerciseCount) EXERCISES",
                color: AppColors.secondary
            )

            Spacer(minLength: 0)
        }
    }
}

private struct ActiveWorkoutMetric: View {
    let systemName: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)

            Text(text)
                .font(AppFonts.Body.bold(12))
                .foregroundStyle(AppColors.onBackground)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

private extension ActiveWorkoutProgress {
    var routineSnapshot: Routine {
        Routine(
            id: routineID,
            userID: "",
            name: routineName,
            exercises: exercises.enumerated().map { index, exercise in
                let routineExerciseID = "cached-routine-exercise-\(exercise.exerciseID)-\(index)"

                return RoutineExercise(
                    id: routineExerciseID,
                    routineID: routineID,
                    exerciseID: exercise.exerciseID,
                    orderIndex: exercise.orderIndex,
                    exercise: Exercise(
                        id: exercise.exerciseID,
                        name: exercise.name,
                        equipment: exercise.equipment,
                        primaryMuscle: exercise.primaryMuscle,
                        secondaryMuscles: exercise.secondaryMuscles,
                        difficulty: exercise.difficulty,
                        movementMode: exercise.movementMethod,
                        isActive: true
                    ),
                    sets: exercise.sets.map { set in
                        RoutineSet(
                            id: "cached-set-\(exercise.exerciseID)-\(set.setNumber)",
                            routineExerciseID: routineExerciseID,
                            setNumber: set.setNumber,
                            minReps: set.plannedMinReps,
                            maxReps: set.plannedMaxReps,
                            targetWeightKG: set.plannedWeightKG,
                            createdAt: "",
                            updatedAt: ""
                        )
                    },
                    createdAt: "",
                    updatedAt: ""
                )
            },
            createdAt: "",
            updatedAt: ""
        )
    }
}

private struct WorkoutMessageView: View {
    let systemName: String
    let title: String
    let actionTitle: String?
    let action: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemName)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(AppColors.onSurfaceVariant)

            Text(title)
                .font(AppFonts.Body.bold(15))
                .foregroundStyle(AppColors.onBackground)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppFonts.Body.bold(11))
                        .foregroundStyle(AppColors.primaryFixed.opacity(0.72))
                        .frame(height: 34)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 145)
        .background(AppColors.surface.opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(AppColors.outlineVariant.opacity(0.34), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
        )
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}
