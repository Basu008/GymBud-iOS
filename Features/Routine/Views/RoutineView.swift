//
//  RoutineView.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import SwiftUI

struct RoutineView: View {
    @StateObject private var viewModel = RoutineViewModel()
    @State private var isCreatingRoutine = false
    @State private var editingRoutine: Routine?
    @State private var didLoadInitialData: Bool

    init(initialRoutines: [Routine]? = nil, initialErrorMessage: String? = nil) {
        _viewModel = StateObject(wrappedValue: RoutineViewModel(
            initialRoutines: initialRoutines ?? [],
            initialErrorMessage: initialErrorMessage
        ))
        _didLoadInitialData = State(initialValue: initialRoutines != nil || initialErrorMessage != nil)
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    GBPrimaryButton(title: "CREATE NEW ROUTINE") {
                        isCreatingRoutine = true
                    }
                        .padding(.top, 26)

                    HStack(alignment: .firstTextBaseline) {
                        Text("ACTIVE LIBRARY")
                            .font(AppFonts.Body.bold(13))
                            .tracking(1.2)
                            .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.78))

                        Spacer()

                        Text("\(viewModel.routines.count) Routines")
                            .font(AppFonts.Body.bold(13))
                            .foregroundStyle(AppColors.secondary)
                    }
                    .padding(.top, 2)

                    routineContent
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 18)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height, alignment: .top)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.always)
            .refreshable {
                await viewModel.loadRoutines()
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .task {
            guard !didLoadInitialData else { return }
            didLoadInitialData = true
            await viewModel.loadRoutines()
        }
        .fullScreenCover(isPresented: $isCreatingRoutine) {
            NewRoutineView()
        }
        .fullScreenCover(item: $editingRoutine) { routine in
            EditRoutineView(routine: routine)
        }
    }

    @ViewBuilder
    private var routineContent: some View {
        if viewModel.isLoading && viewModel.routines.isEmpty {
            RoutineLoadingView()
                .padding(.top, 42)
        } else if let errorMessage = viewModel.errorMessage {
            RoutineMessageView(
                systemName: "exclamationmark.triangle",
                title: errorMessage,
                actionTitle: "TRY AGAIN"
            ) {
                Task {
                    await viewModel.loadRoutines()
                }
            }
            .padding(.top, 42)
        } else if viewModel.routines.isEmpty {
            RoutineMessageView(
                systemName: "list.bullet.clipboard",
                title: "No routines yet",
                actionTitle: nil,
                action: nil
            )
            .padding(.top, 42)
        } else {
            VStack(spacing: 14) {
                ForEach(viewModel.routines) { routine in
                    RoutineCardView(
                        routine: routine,
                        isDeleting: viewModel.deletingRoutineIDs.contains(routine.id),
                        onEdit: {
                            editingRoutine = routine
                        },
                        onDelete: {
                            Task {
                                await viewModel.deleteRoutine(routine)
                            }
                        }
                    )
                        .onAppear {
                            Task {
                                await viewModel.loadMoreRoutinesIfNeeded(currentRoutine: routine)
                            }
                        }
                }

                if viewModel.isLoadingMore {
                    ProgressView()
                        .tint(AppColors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
        }
    }
}

private struct RoutineCardView: View {
    let routine: Routine
    let isDeleting: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(routine.exerciseCountColor)
                .frame(width: 5)
                .shadow(color: routine.exerciseCountColor.opacity(0.55), radius: 8, x: 0, y: 0)

            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.name)
                        .font(AppFonts.Headline.bold(23))
                        .foregroundStyle(AppColors.onBackground)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text("\(routine.exercises.count) EXERCISES")
                        .font(AppFonts.Body.bold(12))
                        .tracking(0.2)
                        .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.86))
                }

                Spacer(minLength: 12)

                Button(action: onDelete) {
                    Group {
                        if isDeleting {
                            ProgressView()
                                .tint(AppColors.onSurfaceVariant)
                        } else {
                            Image(systemName: "trash")
                                .font(.system(size: 21, weight: .semibold))
                        }
                    }
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .frame(width: 38, height: 38)
                }
                .buttonStyle(.plain)
                .disabled(isDeleting)
                .accessibilityLabel("Delete \(routine.name)")
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)
        }
        .frame(height: 100)
        .background(AppColors.surfaceVariant.opacity(0.34))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onTapGesture(perform: onEdit)
    }
}

private extension Routine {
    var exerciseCountColor: Color {
        switch exercises.count {
        case 11...:
            return AppColors.error
        case 8...10:
            return AppColors.success
        case 6...7:
            return Color(hex: "#FFD166")
        default:
            return AppColors.secondary
        }
    }
}

private struct RoutineLoadingView: View {
    var body: some View {
        HStack {
            Spacer()

            ProgressView()
                .tint(AppColors.primary)

            Spacer()
        }
        .frame(height: 120)
    }
}

private struct RoutineMessageView: View {
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
