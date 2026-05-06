//
//  AnalyticsView.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import SwiftUI

struct AnalyticsView: View {
    @State private var analytics: WorkoutAnalyticsPayload?
    @State private var workouts: [WorkoutLog] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var didLoadInitialData: Bool

    private let workoutService: any WorkoutServiceProtocol = WorkoutService()

    init(
        initialAnalytics: WorkoutAnalyticsPayload? = nil,
        initialWorkouts: [WorkoutLog]? = nil,
        initialErrorMessage: String? = nil
    ) {
        _analytics = State(initialValue: initialAnalytics)
        _workouts = State(initialValue: initialWorkouts ?? [])
        _errorMessage = State(initialValue: initialErrorMessage)
        _didLoadInitialData = State(initialValue: initialAnalytics != nil || initialWorkouts != nil || initialErrorMessage != nil)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        Text("IMPACT TILL NOW")
                            .font(AppFonts.Headline.bold(26))
                            .foregroundStyle(AppColors.onBackground)
                            .padding(.top, 24)

                        content
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 18)
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height, alignment: .top)
                }
                .scrollIndicators(.hidden)
                .refreshable {
                    await loadAnalytics()
                }
            }
            .navigationBarHidden(true)
            .task {
                guard !didLoadInitialData else { return }
                didLoadInitialData = true
                await loadAnalytics()
            }
            .background(AppColors.background.ignoresSafeArea())
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && analytics == nil && workouts.isEmpty {
            ProgressView()
                .tint(AppColors.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 220)
        } else if let errorMessage, analytics == nil {
            AnalyticsMessageView(title: errorMessage) {
                Task {
                    await loadAnalytics()
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 22) {
                statsSection
                workoutHistorySection
            }
        }
    }

    private var statsSection: some View {
        let stats = analytics?.stats ?? WorkoutAnalyticsStats.empty

        return VStack(spacing: 16) {
            AnalyticsVolumeCard(totalVolume: stats.totalVolume)

            HStack(spacing: 16) {
                AnalyticsMetricCard(title: "WORKOUTS", value: "\(stats.workoutsCount)", accent: AppColors.secondary)
                AnalyticsMetricCard(title: "SETS COMPLETED", value: "\(stats.totalSets)", accent: AppColors.primary)
            }

            HStack(spacing: 16) {
                AnalyticsMetricCard(title: "TOTAL REPS", value: "\(stats.totalReps)", accent: AppColors.secondary)
                AnalyticsMetricCard(title: "NEW PRS", value: "\(stats.prCount)", accent: AppColors.primary, badgeSystemName: "medal.star")
            }
        }
    }

    private var workoutHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("WORKOUT HISTORY")
                    .font(AppFonts.Headline.bold(22))
                    .foregroundStyle(AppColors.onBackground)

                Spacer()

                NavigationLink {
                    WorkoutHistoryListView(userID: analytics?.userID)
                } label: {
                    Text("View All")
                        .font(AppFonts.Body.bold(14))
                        .foregroundStyle(AppColors.secondary)
                }
                .buttonStyle(.plain)
            }

            if workouts.isEmpty {
                Text("No workouts logged yet.")
                    .font(AppFonts.Body.bold(14))
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 92)
                    .background(AppColors.surfaceVariant.opacity(0.32))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                VStack(spacing: 16) {
                    ForEach(workouts.prefix(5)) { workout in
                        NavigationLink {
                            WorkoutHistoryDetailView(workout: workout) { deletedID in
                                workouts.removeAll { $0.id == deletedID }
                            }
                        } label: {
                            AnalyticsWorkoutRow(workout: workout)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @MainActor
    private func loadAnalytics() async {
        guard !isLoading else { return }

        guard let accessToken = workoutService.storedAccessToken(),
              !accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            errorMessage = "Please log in again to load analytics."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let analytics = try await workoutService.analytics(accessToken: accessToken)
            self.analytics = analytics
            workouts = try await workoutService.userWorkouts(userID: analytics.userID, page: 1, accessToken: accessToken)
        } catch {
            errorMessage = "Unable to load analytics."
        }

        isLoading = false
    }
}

private struct AnalyticsVolumeCard: View {
    let totalVolume: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Total Volume")
                .font(AppFonts.Body.medium(18))
                .foregroundStyle(AppColors.onSurfaceVariant)

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(AnalyticsFormatters.wholeNumber(totalVolume))
                    .font(AppFonts.Headline.bold(62))
                    .foregroundStyle(AppColors.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .layoutPriority(1)

                Text("kg")
                    .font(AppFonts.Body.bold(16))
                    .foregroundStyle(AppColors.primaryFixed)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .background(AppColors.surfaceVariant.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct AnalyticsMetricCard: View {
    let title: String
    let value: String
    let accent: Color
    var badgeSystemName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFonts.Body.medium(12))
                .foregroundStyle(AppColors.onSurfaceVariant)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(value)
                    .font(AppFonts.Headline.bold(40))
                    .foregroundStyle(accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.66)

                if let badgeSystemName {
                    Image(systemName: badgeSystemName)
                        .font(.system(size: 21, weight: .bold))
                        .foregroundStyle(AppColors.primary)
                        .padding(.bottom, 8)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 108)
        .background(AppColors.surfaceVariant.opacity(0.58))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(accent)
                .frame(width: 4)
        }
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}

private struct AnalyticsWorkoutRow: View {
    let workout: WorkoutLog

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 13) {
                Text(workout.title)
                    .font(AppFonts.Headline.bold(18))
                    .foregroundStyle(AppColors.onBackground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)

                HStack(spacing: 13) {
                    AnalyticsRowMetric(systemName: "calendar", text: AnalyticsFormatters.shortDate(workout.startedAt), color: AppColors.onSurfaceVariant)
                    AnalyticsRowMetric(systemName: "clock", text: DurationFormatters.workoutDuration(seconds: workout.durationSec), color: AppColors.secondary)
                    AnalyticsRowMetric(systemName: "figure.strengthtraining.traditional", text: "\(AnalyticsFormatters.wholeNumber(workout.stats?.totalVolume ?? workout.totalVolumeKG)) kg", color: AppColors.primary)
                }
            }

            Spacer(minLength: 12)

            Image(systemName: "chevron.right")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(AppColors.onSurfaceVariant)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 98)
        .background(AppColors.surfaceVariant.opacity(0.34))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct AnalyticsRowMetric: View {
    let systemName: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(color)

            Text(text)
                .font(AppFonts.Body.medium(13))
                .foregroundStyle(AppColors.onSurfaceVariant)
        }
    }
}

private struct WorkoutHistoryListView: View {
    let userID: String?

    @Environment(\.dismiss) private var dismiss
    @State private var workouts: [WorkoutLog] = []
    @State private var page = 1
    @State private var isLoading = false
    @State private var canLoadMore = true
    @State private var errorMessage: String?

    private let workoutService: any WorkoutServiceProtocol = WorkoutService()

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    if let errorMessage, workouts.isEmpty {
                        AnalyticsMessageView(title: errorMessage) {
                            Task {
                                await loadWorkouts(reset: true)
                            }
                        }
                    } else {
                        VStack(spacing: 14) {
                            ForEach(workouts) { workout in
                                NavigationLink {
                                    WorkoutHistoryDetailView(workout: workout) { deletedID in
                                        workouts.removeAll { $0.id == deletedID }
                                    }
                                } label: {
                                    AnalyticsWorkoutRow(workout: workout)
                                }
                                .buttonStyle(.plain)
                            }

                            if isLoading {
                                ProgressView()
                                    .tint(AppColors.primary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                            } else if canLoadMore {
                                Button {
                                    Task {
                                        await loadWorkouts(reset: false)
                                    }
                                } label: {
                                    Text("LOAD MORE")
                                        .font(AppFonts.Body.bold(12))
                                        .foregroundStyle(AppColors.primary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 46)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarHidden(true)
        .task {
            await loadWorkouts(reset: true)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppColors.onBackground)
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            Text("WORKOUT HISTORY")
                .font(AppFonts.Headline.bold(24))
                .foregroundStyle(AppColors.onBackground)

            Spacer()
        }
    }

    @MainActor
    private func loadWorkouts(reset: Bool) async {
        guard !isLoading else { return }

        guard let userID else {
            errorMessage = "Unable to find your workout history."
            return
        }

        guard let accessToken = workoutService.storedAccessToken(),
              !accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            errorMessage = "Please log in again to load workouts."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let nextPage = reset ? 1 : page + 1
            let nextWorkouts = try await workoutService.userWorkouts(userID: userID, page: nextPage, accessToken: accessToken)

            workouts = reset ? nextWorkouts : workouts + nextWorkouts
            page = nextPage
            canLoadMore = !nextWorkouts.isEmpty
        } catch {
            errorMessage = "Unable to load workouts."
        }

        isLoading = false
    }
}

private struct WorkoutHistoryDetailView: View {
    let workout: WorkoutLog
    let onDelete: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isShowingDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var deleteErrorMessage: String?

    private let workoutService: any WorkoutServiceProtocol = WorkoutService()

    private var totalSets: Int {
        workout.stats?.totalSets ?? workout.exercises.reduce(0) { $0 + $1.sets.count }
    }

    private var totalReps: Int {
        workout.stats?.totalReps ?? workout.exercises.flatMap(\.sets).compactMap(\.actualReps).reduce(0, +)
    }

    private var prCount: Int {
        workout.exercises.flatMap(\.sets).filter { set in
            set.prFlags?.weightPR == true || set.prFlags?.repPR == true || set.prFlags?.estimated1RMPR == true
        }.count
    }

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    detailStats
                    exerciseBreakdown
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarHidden(true)
        .alert("Delete Workout?", isPresented: $isShowingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await deleteWorkout()
                }
            }
        } message: {
            Text("This workout will be removed from your history.")
        }
        .alert("Unable to Delete Workout", isPresented: Binding(
            get: { deleteErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    deleteErrorMessage = nil
                }
            }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteErrorMessage ?? "")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppColors.onBackground)
                        .frame(width: 38, height: 38, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")

                Spacer()

                Button {
                    isShowingDeleteConfirmation = true
                } label: {
                    ZStack {
                        if isDeleting {
                            ProgressView()
                                .tint(AppColors.error)
                        } else {
                            Image(systemName: "trash")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(AppColors.error)
                        }
                    }
                    .frame(width: 38, height: 38)
                }
                .buttonStyle(.plain)
                .disabled(isDeleting)
                .accessibilityLabel("Delete workout")
            }

            VStack(alignment: .leading, spacing: 7) {
                Text(workout.title)
                    .font(AppFonts.Headline.bold(32))
                    .foregroundStyle(AppColors.onBackground)
                    .lineLimit(2)
                    .minimumScaleFactor(0.76)

                Text("\(AnalyticsFormatters.fullDate(workout.startedAt)) • \(DurationFormatters.workoutDuration(seconds: workout.durationSec))")
                    .font(AppFonts.Body.bold(13))
                    .foregroundStyle(AppColors.onSurfaceVariant)
            }
        }
    }

    @MainActor
    private func deleteWorkout() async {
        guard !isDeleting else { return }

        guard let accessToken = workoutService.storedAccessToken(),
              !accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            deleteErrorMessage = "Please log in again to delete this workout."
            return
        }

        isDeleting = true

        do {
            let deletedID = try await workoutService.deleteWorkout(id: workout.id, accessToken: accessToken)
            onDelete(deletedID)
            dismiss()
        } catch {
            deleteErrorMessage = "Please try again."
        }

        isDeleting = false
    }

    private var detailStats: some View {
        VStack(spacing: 12) {
            WorkoutDetailStatCard(title: "TOTAL VOLUME", value: AnalyticsFormatters.wholeNumber(workout.stats?.totalVolume ?? workout.totalVolumeKG), unit: "KG", isWide: true)

            HStack(spacing: 12) {
                WorkoutDetailStatCard(title: "SETS", value: "\(totalSets)", unit: nil)
                WorkoutDetailStatCard(title: "REPS", value: "\(totalReps)", unit: nil)
                WorkoutDetailStatCard(title: "PRS", value: "\(prCount)", unit: nil)
            }
        }
    }

    private var exerciseBreakdown: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("EXERCISE BREAKDOWN")
                .font(AppFonts.Headline.bold(20))
                .foregroundStyle(AppColors.onBackground)

            VStack(spacing: 12) {
                ForEach(workout.exercises.sorted { $0.orderIndex < $1.orderIndex }) { exercise in
                    WorkoutHistoryExerciseCard(exercise: exercise)
                }
            }
        }
    }
}

private struct WorkoutDetailStatCard: View {
    let title: String
    let value: String
    let unit: String?
    var isWide = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFonts.Body.bold(10))
                .tracking(0.9)
                .foregroundStyle(AppColors.onSurfaceVariant)

            HStack(alignment: .lastTextBaseline, spacing: 5) {
                Text(value)
                    .font(AppFonts.Headline.bold(isWide ? 36 : 27))
                    .foregroundStyle(AppColors.success)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)

                if let unit {
                    Text(unit)
                        .font(AppFonts.Body.bold(12))
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: isWide ? 96 : 84)
        .background(AppColors.surfaceVariant.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct WorkoutHistoryExerciseCard: View {
    let exercise: WorkoutExerciseLog

    private var completedSets: [WorkoutSetLog] {
        exercise.sets
            .sorted { $0.setNumber < $1.setNumber }
            .filter { $0.actualReps != nil && $0.actualWeightKG != nil }
    }

    private var totalVolume: Double {
        completedSets.reduce(0) { total, set in
            total + Double(set.actualReps ?? 0) * (set.actualWeightKG ?? 0)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(exercise.exerciseName)
                        .font(AppFonts.Headline.bold(17))
                        .foregroundStyle(AppColors.onBackground)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)

                    Text("\(completedSets.count) Sets")
                        .font(AppFonts.Body.medium(11))
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(AnalyticsFormatters.decimalNumber(totalVolume)) kg")
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
            .padding(.horizontal, 16)
            .padding(.vertical, 18)

            HStack(spacing: 0) {
                ForEach(completedSets) { set in
                    VStack(spacing: 6) {
                        Text("SET \(set.setNumber)")
                            .font(AppFonts.Body.bold(8))
                            .foregroundStyle(AppColors.onSurfaceVariant)

                        Text("\(AnalyticsFormatters.decimalNumber(set.actualWeightKG ?? 0))x\(set.actualReps ?? 0)")
                            .font(AppFonts.Body.bold(12))
                            .foregroundStyle(set.isPR ? AppColors.success : AppColors.onBackground)
                            .lineLimit(1)
                            .minimumScaleFactor(0.76)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                }
            }
            .background(AppColors.surfaceVariant.opacity(0.74))
        }
        .background(AppColors.surface.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct AnalyticsMessageView: View {
    let title: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(AppColors.onSurfaceVariant)

            Text(title)
                .font(AppFonts.Body.bold(15))
                .foregroundStyle(AppColors.onBackground)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)

            Button(action: action) {
                Text("TRY AGAIN")
                    .font(AppFonts.Body.bold(11))
                    .foregroundStyle(AppColors.primaryFixed.opacity(0.72))
                    .frame(height: 34)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 145)
        .background(AppColors.surfaceVariant.opacity(0.32))
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}

private enum AnalyticsFormatters {
    static func wholeNumber(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0)))
    }

    static func decimalNumber(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)))
    }

    static func shortDate(_ rawValue: String) -> String {
        guard let date = date(from: rawValue) else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date).uppercased()
    }

    static func fullDate(_ rawValue: String) -> String {
        guard let date = date(from: rawValue) else { return rawValue }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private static func date(from rawValue: String) -> Date? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = isoFormatter.date(from: rawValue) {
            return date
        }

        isoFormatter.formatOptions = [.withInternetDateTime]
        return isoFormatter.date(from: rawValue)
    }
}

private extension WorkoutAnalyticsStats {
    static let empty = WorkoutAnalyticsStats(
        workoutsCount: 0,
        totalVolume: 0,
        totalSets: 0,
        totalReps: 0,
        prCount: 0
    )
}

private extension WorkoutLog {
    var totalVolumeKG: Double {
        exercises
            .flatMap(\.sets)
            .reduce(0) { total, set in
                total + Double(set.actualReps ?? 0) * (set.actualWeightKG ?? 0)
            }
    }
}

private extension WorkoutSetLog {
    var isPR: Bool {
        prFlags?.weightPR == true || prFlags?.repPR == true || prFlags?.estimated1RMPR == true
    }
}

#Preview {
    AnalyticsView()
}
