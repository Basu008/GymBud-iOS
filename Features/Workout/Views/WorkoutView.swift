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
    @State private var selectedRoutine: Routine?
    @State private var didLoadInitialData: Bool
    private let routineService: any RoutineServiceProtocol = RoutineService()

    init(initialRoutines: [Routine]? = nil, initialErrorMessage: String? = nil) {
        _routines = State(initialValue: initialRoutines ?? [])
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

                    content
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 18)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height, alignment: .top)
            }
            .scrollIndicators(.hidden)
            .refreshable {
                await loadRoutines()
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .task {
            guard !didLoadInitialData else { return }
            didLoadInitialData = true
            await loadRoutines()
        }
        .fullScreenCover(item: $selectedRoutine) { routine in
            LogWorkoutView(routine: routine)
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
                        selectedRoutine = routine
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

    private func loadRoutines() async {
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
            routines = try await routineService.routines(page: 1, accessToken: accessToken)
        } catch {
            errorMessage = "Unable to load routines."
        }

        isLoading = false
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
