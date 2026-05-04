//
//  CompleteWorkoutSummaryView.swift
//  GymBud
//
//  Created by Codex on 03/05/26.
//

import SwiftUI

struct CompleteWorkoutSummaryView: View {
    let workout: WorkoutLog
    let routine: Routine
    let onClose: () -> Void

    private var summaries: [CompletedExerciseSummary] {
        workout.exercises
            .sorted { $0.orderIndex < $1.orderIndex }
            .map { CompletedExerciseSummary(exercise: $0, routineExercise: routineExercise(for: $0.exerciseID)) }
    }

    private var prSets: [CompletedSetSummary] {
        summaries.flatMap(\.sets).filter { $0.prType != nil }
    }

    private var totalVolumeLbs: Double {
        summaries.reduce(0) { $0 + $1.totalVolumeLbs }
    }

    private var totalSets: Int {
        workout.stats?.totalSets ?? summaries.reduce(0) { $0 + $1.sets.count }
    }

    private var totalReps: Int {
        workout.stats?.totalReps ?? summaries.flatMap(\.sets).reduce(0) { $0 + $1.reps }
    }

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    hero
                    statsGrid
                    prHighlights
                    exerciseBreakdown
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text("SESSION ACCOMPLISHED")
                    .font(AppFonts.Body.bold(11))
                    .tracking(2.2)
                    .foregroundStyle(AppColors.success)

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppColors.onSurfaceVariant)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close workout summary")
            }

            Text("WORKOUT\nCOMPLETE")
                .font(AppFonts.Headline.bold(44))
                .italic()
                .foregroundStyle(AppColors.onBackground)
                .lineSpacing(4)
                .minimumScaleFactor(0.82)
        }
        .padding(.horizontal, 18)
        .padding(.top, 22)
        .padding(.bottom, 26)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surfaceVariant.opacity(0.24))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var statsGrid: some View {
        VStack(spacing: 12) {
            CompleteWorkoutStatCard(
                title: "TOTAL VOLUME",
                value: Self.formattedWhole(totalVolumeLbs),
                unit: "LBS",
                isWide: true
            )

            HStack(spacing: 12) {
                CompleteWorkoutStatCard(title: "SETS", value: "\(totalSets)", unit: nil)
                CompleteWorkoutStatCard(title: "REPS", value: "\(totalReps)", unit: nil)
            }
        }
    }

    @ViewBuilder
    private var prHighlights: some View {
        if !prSets.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text("PR HIGHLIGHTS")
                        .font(AppFonts.Headline.bold(20))
                        .italic()
                        .foregroundStyle(AppColors.onBackground)

                    Spacer()

                    Text("NEW PEAKS DETECTED")
                        .font(AppFonts.Body.bold(9))
                        .foregroundStyle(AppColors.error)
                }

                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(prSets) { set in
                            CompleteWorkoutPRCard(set: set)
                        }
                    }
                    .padding(.trailing, 20)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    private var exerciseBreakdown: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("EXERCISE BREAKDOWN")
                .font(AppFonts.Headline.bold(20))
                .italic()
                .foregroundStyle(AppColors.onBackground)

            VStack(spacing: 12) {
                ForEach(summaries) { summary in
                    CompleteWorkoutExerciseCard(summary: summary)
                }
            }
        }
    }

    private func routineExercise(for exerciseID: String) -> RoutineExercise? {
        routine.exercises.first { $0.exerciseID == exerciseID }
    }

    static func pounds(from kilograms: Double) -> Double {
        kilograms * 2.2046226218
    }

    static func formattedWhole(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0)))
    }

    static func formattedWeightLbs(_ kilograms: Double) -> String {
        formattedWhole(pounds(from: kilograms))
    }
}

private struct CompleteWorkoutStatCard: View {
    let title: String
    let value: String
    let unit: String?
    var isWide = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppFonts.Body.bold(10))
                .tracking(0.9)
                .foregroundStyle(AppColors.onSurfaceVariant)

            HStack(alignment: .lastTextBaseline, spacing: 5) {
                Text(value)
                    .font(AppFonts.Headline.bold(isWide ? 36 : 28))
                    .foregroundStyle(AppColors.success)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                if let unit {
                    Text(unit)
                        .font(AppFonts.Body.bold(12))
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }
            }
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: isWide ? 100 : 86)
        .background(AppColors.surfaceVariant.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct CompleteWorkoutPRCard: View {
    let set: CompletedSetSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: "sparkle")
                    .font(.system(size: 9, weight: .bold))

                Text(set.exerciseName.uppercased())
                    .font(AppFonts.Body.bold(9))
                    .tracking(0.7)
                    .lineLimit(1)
            }
            .foregroundStyle(AppColors.success)

            Text("\(set.weightLbsText) x \(set.reps)")
                .font(AppFonts.Headline.bold(25))
                .foregroundStyle(AppColors.onBackground)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Text(set.prType?.label.uppercased() ?? "PR")
                .font(AppFonts.Body.bold(10))
                .foregroundStyle(AppColors.success)
        }
        .padding(.horizontal, 16)
        .frame(width: 214, height: 116, alignment: .leading)
        .background(AppColors.surfaceVariant.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct CompleteWorkoutExerciseCard: View {
    let summary: CompletedExerciseSummary

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(summary.name)
                        .font(AppFonts.Headline.bold(17))
                        .foregroundStyle(AppColors.onBackground)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)

                    Text(summary.subtitle)
                        .font(AppFonts.Body.medium(11))
                        .foregroundStyle(AppColors.onSurfaceVariant)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(CompleteWorkoutSummaryView.formattedWhole(summary.totalVolumeLbs)) lbs")
                        .font(AppFonts.Headline.bold(16))
                        .foregroundStyle(AppColors.success)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Text("TOTAL LOAD")
                        .font(AppFonts.Body.bold(8))
                        .tracking(1.2)
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)

            HStack(spacing: 0) {
                ForEach(summary.sets) { set in
                    VStack(spacing: 6) {
                        Text("SET \(set.setNumber)")
                            .font(AppFonts.Body.bold(8))
                            .foregroundStyle(AppColors.onSurfaceVariant)

                        Text("\(set.weightLbsText)x\(set.reps)")
                            .font(AppFonts.Body.bold(12))
                            .foregroundStyle(set.resultColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.76)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                }
            }
            .background(AppColors.surfaceVariant.opacity(0.8))
        }
        .background(AppColors.surface.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct CompletedExerciseSummary: Identifiable {
    let id: String
    let name: String
    let sets: [CompletedSetSummary]
    let primaryMuscle: String?
    let secondaryMuscles: [String]
    let volumeMultiplier: Double

    init(exercise: WorkoutExerciseLog, routineExercise: RoutineExercise?) {
        id = exercise.exerciseID
        name = exercise.exerciseName
        primaryMuscle = routineExercise?.exercise.primaryMuscle
        secondaryMuscles = routineExercise?.exercise.secondaryMuscles ?? []
        let isUnilateral = routineExercise?.exercise.movementMode?.caseInsensitiveCompare("unilateral") == .orderedSame
        let isDumbbell = routineExercise?.exercise.equipment?.caseInsensitiveCompare("dumbbell") == .orderedSame
        let multiplier = isUnilateral || isDumbbell ? 2.0 : 1.0
        volumeMultiplier = multiplier
        sets = exercise.sets
            .sorted { $0.setNumber < $1.setNumber }
            .compactMap { CompletedSetSummary(set: $0, exerciseName: exercise.exerciseName, volumeMultiplier: multiplier) }
    }

    var totalVolumeLbs: Double {
        sets.reduce(0) { $0 + $1.volumeLbs }
    }

    var subtitle: String {
        let muscles = ([primaryMuscle].compactMap { $0 } + secondaryMuscles)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        guard !muscles.isEmpty else {
            return "\(sets.count) Sets"
        }

        return "\(sets.count) Sets • \(muscles.prefix(2).joined(separator: ", "))"
    }
}

private struct CompletedSetSummary: Identifiable {
    let id = UUID()
    let setNumber: Int
    let exerciseName: String
    let reps: Int
    let weightKG: Double
    let plannedMaxReps: Int?
    let plannedWeightKG: Double?
    let volumeMultiplier: Double
    let prType: WorkoutPRType?

    init?(set: WorkoutSetLog, exerciseName: String, volumeMultiplier: Double) {
        guard let reps = set.actualReps,
              let weightKG = set.actualWeightKG
        else {
            return nil
        }

        setNumber = set.setNumber
        self.exerciseName = exerciseName
        self.reps = reps
        self.weightKG = weightKG
        plannedMaxReps = set.plannedMaxReps
        plannedWeightKG = set.plannedWeightKG
        self.volumeMultiplier = volumeMultiplier
        prType = WorkoutPRType(flags: set.prFlags)
    }

    var weightLbsText: String {
        CompleteWorkoutSummaryView.formattedWeightLbs(weightKG)
    }

    var volumeLbs: Double {
        CompleteWorkoutSummaryView.pounds(from: Double(reps) * weightKG * volumeMultiplier)
    }

    var isBelowPlanned: Bool {
        guard let plannedMaxReps,
              let plannedWeightKG
        else {
            return false
        }

        return Double(reps) * weightKG < Double(plannedMaxReps) * plannedWeightKG
    }

    var resultColor: Color {
        if prType != nil {
            return AppColors.success
        }

        if isBelowPlanned {
            return AppColors.error
        }

        return AppColors.onBackground
    }
}

private enum WorkoutPRType {
    case weight
    case reps
    case estimated1RM

    init?(flags: WorkoutSetPRFlags?) {
        guard let flags else { return nil }

        if flags.weightPR {
            self = .weight
        } else if flags.repPR {
            self = .reps
        } else if flags.estimated1RMPR {
            self = .estimated1RM
        } else {
            return nil
        }
    }

    var label: String {
        switch self {
        case .weight:
            return "Weight PR"
        case .reps:
            return "Rep PR"
        case .estimated1RM:
            return "Estimated 1RM PR"
        }
    }
}

#Preview {
    CompleteWorkoutSummaryView(
        workout: WorkoutLog(
            id: "workout-1",
            userID: "user-1",
            routineID: "routine-1",
            title: "Push Day",
            startedAt: "",
            endedAt: "",
            durationSec: 3600,
            visibility: "all",
            exercises: [],
            stats: WorkoutStats(totalSets: 24, totalReps: 186, totalVolume: 0),
            createdAt: "",
            updatedAt: ""
        ),
        routine: .sample(id: "routine-1", name: "Push Day", exerciseCount: 3),
        onClose: {}
    )
}
