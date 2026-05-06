//
//  ExercisesView.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import SwiftUI

struct ExercisesView: View {
    @StateObject private var viewModel: ExercisesViewModel
    @State private var isCreatingExercise = false
    @State private var searchTask: Task<Void, Never>?
    private let onCancel: () -> Void
    private let onSave: ([Exercise]) -> Void

    init(
        selectedExercises: [Exercise] = [],
        onCancel: @escaping () -> Void = {},
        onSave: @escaping ([Exercise]) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: ExercisesViewModel(selectedExercises: selectedExercises))
        self.onCancel = onCancel
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 22) {
                        searchField
                        filters
                        createExerciseButton
                        exerciseList
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                    .padding(.bottom, 24)
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height, alignment: .top)
                }
                .scrollIndicators(.hidden)
                .refreshable {
                    await viewModel.loadInitialData()
                }
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        .task {
            await viewModel.loadInitialData()
        }
        .onChange(of: viewModel.searchText) {
            scheduleExerciseRefresh()
        }
        .onChange(of: viewModel.selectedCategoryName) {
            Task {
                await viewModel.refreshExercises()
            }
        }
        .sheet(isPresented: $isCreatingExercise) {
            NavigationStack {
                CustomExerciseView { exercise in
                    viewModel.selectExercise(exercise)
                    isCreatingExercise = false
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Button {
                onCancel()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")

            Spacer()

            Button {
                onSave(viewModel.selectedExercises)
            } label: {
                Text("SAVE")
                    .font(AppFonts.Body.bold(11))
                    .foregroundStyle(AppColors.primary)
                    .frame(height: 34)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Save selected exercises")
        }
        .padding(.leading, 16)
        .padding(.trailing, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(Color.black.opacity(0.62))
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.9))

            TextField(
                "",
                text: $viewModel.searchText,
                prompt: Text("Search exercises...").foregroundStyle(AppColors.onSurfaceVariant.opacity(0.82))
            )
            .font(AppFonts.Body.medium(13))
            .foregroundStyle(AppColors.onBackground)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .frame(height: 45)
        .background(AppColors.surfaceVariant.opacity(0.44))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var filters: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(viewModel.filterNames, id: \.self) { filter in
                    ExerciseFilterButton(
                        title: filter,
                        isSelected: viewModel.selectedCategoryName.localizedCaseInsensitiveCompare(filter) == .orderedSame
                    ) {
                        viewModel.selectedCategoryName = filter
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private var createExerciseButton: some View {
        Button {
            isCreatingExercise = true
        } label: {
            HStack(spacing: 9) {
                ZStack {
                    Circle()
                        .fill(AppColors.primary.opacity(0.2))

                    Image(systemName: "plus.circle")
                        .font(.system(size: 21, weight: .bold))
                        .foregroundStyle(AppColors.primary)
                }
                .frame(width: 29, height: 29)

                VStack(alignment: .leading, spacing: 2) {
                    Text("CREATE NEW")
                        .font(AppFonts.Body.bold(8))
                        .foregroundStyle(AppColors.primary)
                        .tracking(0.8)

                    Text("Custom Exercise")
                        .font(AppFonts.Headline.bold(13))
                        .foregroundStyle(AppColors.onBackground)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 62)
            .background(AppColors.primary.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppColors.primary.opacity(0.72), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Create custom exercise")
    }

    @ViewBuilder
    private var exerciseList: some View {
        if viewModel.isLoading {
            ProgressView()
                .tint(AppColors.primary)
                .frame(maxWidth: .infinity)
                .padding(.top, 28)
        } else if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .font(AppFonts.Body.bold(12))
                .foregroundStyle(AppColors.error)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 16)
        } else {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredExercises) { exercise in
                    ExerciseRow(
                        exercise: exercise,
                        isSelected: viewModel.isSelected(exercise)
                    ) {
                        viewModel.toggleSelection(for: exercise)
                    }
                    .onAppear {
                        Task {
                            await viewModel.loadMoreExercisesIfNeeded(currentExercise: exercise)
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

private extension ExercisesView {
    func scheduleExerciseRefresh() {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            await viewModel.refreshExercises()
        }
    }
}

private struct ExerciseFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(AppFonts.Body.bold(9))
                .foregroundStyle(isSelected ? Color.black.opacity(0.78) : AppColors.onSurfaceVariant)
                .frame(minWidth: 50)
                .frame(height: 25)
                .padding(.horizontal, 16)
                .background(isSelected ? AppColors.primary : AppColors.surfaceVariant.opacity(0.78))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct ExerciseRow: View {
    let exercise: Exercise
    let isSelected: Bool
    let onToggleSelection: () -> Void

    private var accentColor: Color {
        switch exercise.difficulty?.lowercased() {
        case "beginner":
            return AppColors.success
        case "intermediate":
            return Color(hex: "#FFD92F")
        case "advanced":
            return AppColors.error
        default:
            return AppColors.onSurfaceVariant
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            Rectangle()
                .fill(accentColor)
                .frame(width: 3)
                .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 8) {
                Text(exercise.name)
                    .font(AppFonts.Headline.bold(13))
                    .foregroundStyle(AppColors.onBackground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                ExerciseFlowLayout(spacing: 6, rowSpacing: 5) {
                    ForEach(Array(exercise.visibleTags.enumerated()), id: \.offset) { _, tag in
                        ExerciseTag(title: tag, isPrimary: tag == exercise.primaryMuscle)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onToggleSelection) {
                Image(systemName: isSelected ? "checkmark" : "plus")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isSelected ? Color.black.opacity(0.78) : AppColors.onBackground)
                    .frame(width: 34, height: 34)
                    .background(isSelected ? AppColors.primary : Color.clear)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(isSelected ? AppColors.primary : AppColors.outlineVariant.opacity(0.66), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isSelected ? "Remove \(exercise.name)" : "Add \(exercise.name)")
            .padding(.trailing, 16)
        }
        .frame(minHeight: 66)
        .background(AppColors.surfaceVariant.opacity(0.32))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ExerciseTag: View {
    let title: String
    let isPrimary: Bool

    var body: some View {
        Text(title.uppercased())
            .font(AppFonts.Body.bold(6.5))
            .foregroundStyle(isPrimary ? AppColors.secondary : AppColors.error)
            .padding(.horizontal, 16)
            .frame(height: 17)
            .background((isPrimary ? AppColors.secondary : AppColors.error).opacity(0.1))
            .overlay(
                Capsule()
                    .stroke((isPrimary ? AppColors.secondary : AppColors.error).opacity(0.2), lineWidth: 1)
            )
            .clipShape(Capsule())
    }
}

private extension Exercise {
    var visibleTags: [String] {
        Array(allMuscleTags.prefix(4))
    }
}

private struct ExerciseFlowLayout: Layout {
    var spacing: CGFloat = 8
    var rowSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(for: subviews, proposalWidth: proposal.width)
        let width = proposal.width ?? rows.map(\.width).max() ?? 0
        let height = rows.map(\.height).reduce(0, +) + rowSpacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY

        for row in rows(for: subviews, proposalWidth: bounds.width) {
            var x = bounds.minX

            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }

            y += row.height + rowSpacing
        }
    }

    private func rows(for subviews: Subviews, proposalWidth: CGFloat?) -> [ExerciseFlowRow] {
        let maxWidth = proposalWidth ?? .infinity
        var rows: [ExerciseFlowRow] = []
        var current = ExerciseFlowRow()

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let proposedWidth = current.width == 0 ? size.width : current.width + spacing + size.width

            if proposedWidth > maxWidth, !current.indices.isEmpty {
                rows.append(current)
                current = ExerciseFlowRow()
            }

            current.indices.append(index)
            current.width = current.width == 0 ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
        }

        if !current.indices.isEmpty {
            rows.append(current)
        }

        return rows
    }
}

private struct ExerciseFlowRow {
    var indices: [Int] = []
    var width: CGFloat = 0
    var height: CGFloat = 0
}

#Preview {
    ExercisesPreview()
}

private struct ExercisesPreview: View {
    var body: some View {
        ExercisesView()
    }
}
