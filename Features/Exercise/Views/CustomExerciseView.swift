//
//  CustomExerciseView.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import Combine
import SwiftUI

struct CustomExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CustomExerciseViewModel()
    private let onExerciseSaved: (Exercise) -> Void

    init(onExerciseSaved: @escaping (Exercise) -> Void = { _ in }) {
        self.onExerciseSaved = onExerciseSaved
    }

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        referenceStatusBanner

                        exerciseDetailsCard

                        anatomicalFocusHeader

                        primaryMuscleCard

                        SecondaryMusclesCard(
                            selectedMuscles: viewModel.selectedSecondaryMuscles,
                            availableMuscles: viewModel.muscles,
                            onAdd: viewModel.selectSecondaryMuscle,
                            onRemove: viewModel.removeSecondaryMuscle
                        )

                        difficultyProfileCard
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 116)
                }
                .scrollIndicators(.hidden)
            }

            VStack {
                Spacer()

                saveButton
                    .padding(.horizontal, 28)
                    .padding(.bottom, 12)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await viewModel.loadReferenceData()
        }
        .onReceive(viewModel.$createdExercise.compactMap { $0 }) { exercise in
            onExerciseSaved(exercise)
            dismiss()
        }
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppColors.onBackground)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")

            Spacer()
        }
        .padding(.leading, 12)
        .padding(.trailing, 28)
        .padding(.top, 17)
        .padding(.bottom, 17)
        .background(Color.black.opacity(0.78))
    }

    private var exerciseDetailsCard: some View {
        CustomExerciseCard {
            VStack(alignment: .leading, spacing: 22) {
                CustomExerciseTextField(
                    title: "EXERCISE NAME",
                    placeholder: "e.g. Incline DB Press",
                    text: $viewModel.exerciseName
                )

                CustomExercisePickerField(
                    title: "CATEGORY",
                    value: viewModel.selectedCategory?.name ?? "Select category",
                    options: viewModel.categories
                ) { option in
                    viewModel.selectedCategory = option
                }

                CustomExercisePickerField(
                    title: "EQUIPMENT",
                    value: viewModel.selectedEquipment?.name ?? "Select equipment",
                    options: viewModel.equipments
                ) { option in
                    viewModel.selectedEquipment = option
                }
            }
        }
    }

    @ViewBuilder
    private var referenceStatusBanner: some View {
        if viewModel.isLoading {
            HStack(spacing: 10) {
                ProgressView()
                    .tint(AppColors.primary)

                Text("Loading exercise options")
                    .font(AppFonts.Body.bold(12))
                    .foregroundStyle(AppColors.onSurfaceVariant)

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 42)
                .background(AppColors.surfaceVariant.opacity(0.56))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else if let successMessage = viewModel.successMessage {
            Text(successMessage)
                .font(AppFonts.Body.bold(12))
                .foregroundStyle(AppColors.primary)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 42)
                .background(AppColors.surfaceVariant.opacity(0.56))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .font(AppFonts.Body.bold(12))
                .foregroundStyle(AppColors.error)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 42)
                .background(AppColors.surfaceVariant.opacity(0.56))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private var anatomicalFocusHeader: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(AppColors.secondary.opacity(0.16))

                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColors.secondary)
            }
            .frame(width: 30, height: 30)

            Text("ANATOMICAL FOCUS")
                .font(AppFonts.Headline.bold(17))
                .foregroundStyle(AppColors.onBackground)
        }
    }

    private var primaryMuscleCard: some View {
        CustomExerciseCard {
            CustomExercisePickerField(
                title: "PRIMARY MUSCLE",
                value: viewModel.selectedPrimaryMuscle?.name ?? "Select muscle",
                options: viewModel.muscles
            ) { option in
                viewModel.selectedPrimaryMuscle = option
            }
        }
    }

    private var difficultyProfileCard: some View {
        CustomExerciseCard {
            VStack(alignment: .leading, spacing: 30) {
                VStack(alignment: .leading, spacing: 18) {
                    CustomExerciseLabel("DIFFICULTY PROFILE")

                    DifficultySelector(
                        difficulties: viewModel.difficulties,
                        selection: $viewModel.selectedDifficulty
                    )
                }

                CustomExerciseMovementModeField(
                    value: $viewModel.movementMode,
                    options: viewModel.movementModeOptions
                )
            }
        }
    }

    private var saveButton: some View {
        Button {
            Task {
                await viewModel.saveExercise()
            }
        } label: {
            HStack(spacing: 11) {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(Color.black.opacity(0.78))
                } else {
                    Text("SAVE EXERCISE")
                        .font(AppFonts.Body.bold(14))
                        .tracking(3.4)

                    Image(systemName: "bolt.fill")
                        .font(.system(size: 14, weight: .bold))
                }
            }
            .foregroundStyle(Color.black.opacity(0.78))
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                LinearGradient(
                    colors: [AppColors.primary.opacity(0.96), AppColors.primaryFixed],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: AppColors.primaryFixed.opacity(0.18), radius: 20, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isSaving)
        .opacity(viewModel.isSaving ? 0.78 : 1)
        .accessibilityLabel("Save exercise")
    }
}

private struct CustomExerciseCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.surfaceVariant.opacity(0.74))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct CustomExerciseLabel: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(AppFonts.Body.bold(10))
            .tracking(1.1)
            .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.86))
    }
}

private struct CustomExerciseTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var trailingSystemName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            CustomExerciseLabel(title)

            HStack(spacing: 10) {
                TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(AppColors.onSurfaceVariant.opacity(0.28)))
                    .font(AppFonts.Body.bold(14))
                    .foregroundStyle(AppColors.onBackground)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()

                if let trailingSystemName {
                    Image(systemName: trailingSystemName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.66))
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(AppColors.surfaceBright.opacity(0.36))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
    }
}

private struct CustomExercisePickerField: View {
    let title: String
    let value: String
    let options: [ExerciseReferenceOption]
    let onSelect: (ExerciseReferenceOption) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            CustomExerciseLabel(title)

            Menu {
                ForEach(options) { option in
                    Button(option.name) {
                        onSelect(option)
                    }
                }
            } label: {
                HStack {
                    Text(value)
                        .font(AppFonts.Body.bold(13))
                        .foregroundStyle(AppColors.onBackground)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.82))
                }
                .padding(.horizontal, 16)
                .frame(height: 54)
                .background(AppColors.surfaceBright.opacity(0.36))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .disabled(options.isEmpty)
        }
    }
}

private struct CustomExerciseMovementModeField: View {
    @Binding var value: String
    let options: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            CustomExerciseLabel("MOVEMENT MODE (OPTIONAL)")

            Menu {
                ForEach(options, id: \.self) { option in
                    Button(displayName(for: option)) {
                        value = option
                    }
                }
            } label: {
                HStack {
                    Text(displayName(for: value))
                        .font(AppFonts.Body.bold(13))
                        .foregroundStyle(value.isEmpty ? AppColors.onSurfaceVariant.opacity(0.76) : AppColors.onBackground)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.82))
                }
                .padding(.horizontal, 16)
                .frame(height: 54)
                .background(AppColors.surfaceBright.opacity(0.36))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
        }
    }

    private func displayName(for option: String) -> String {
        option.isEmpty ? "None" : option.capitalized
    }
}

private struct SecondaryMusclesCard: View {
    let selectedMuscles: [ExerciseReferenceOption]
    let availableMuscles: [ExerciseReferenceOption]
    let onAdd: (ExerciseReferenceOption) -> Void
    let onRemove: (ExerciseReferenceOption) -> Void

    var body: some View {
        CustomExerciseCard {
            VStack(alignment: .leading, spacing: 14) {
                CustomExerciseLabel("SECONDARY MUSCLES")

                FlowLayout(spacing: 8, rowSpacing: 8) {
                    ForEach(selectedMuscles) { muscle in
                        MuscleChip(title: muscle.name) {
                            onRemove(muscle)
                        }
                    }

                    Menu {
                        ForEach(availableMuscles.filter { !selectedMuscles.contains($0) }) { muscle in
                            Button(muscle.name) {
                                onAdd(muscle)
                            }
                        }
                    } label: {
                        Text("+ Add Muscle")
                            .font(AppFonts.Body.bold(10))
                            .foregroundStyle(AppColors.onBackground.opacity(0.8))
                            .padding(.horizontal, 13)
                            .frame(height: 28)
                            .overlay(
                                Capsule()
                                    .stroke(AppColors.onSurfaceVariant.opacity(0.36), lineWidth: 1)
                            )
                    }
                    .disabled(availableMuscles.isEmpty)
                }
            }
        }
    }
}

private struct MuscleChip: View {
    let title: String
    let onRemove: () -> Void

    var body: some View {
        Button(action: onRemove) {
            HStack(spacing: 7) {
                Text(title)
                    .font(AppFonts.Body.bold(10))

                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
            }
            .foregroundStyle(AppColors.secondary)
            .padding(.horizontal, 13)
            .frame(height: 28)
            .background(AppColors.secondary.opacity(0.12))
            .overlay(
                Capsule()
                    .stroke(AppColors.secondary.opacity(0.35), lineWidth: 1)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct DifficultySelector: View {
    let difficulties: [ExerciseReferenceOption]
    @Binding var selection: ExerciseReferenceOption?

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(difficulties.enumerated()), id: \.element.id) { index, difficulty in
                DifficultyButton(difficulty: difficulty, isSelected: selection == difficulty) {
                    selection = difficulty
                }

                if index < difficulties.count - 1 {
                    Rectangle()
                        .fill(AppColors.outlineVariant.opacity(0.48))
                        .frame(height: 1)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 18)
                }
            }
        }
        .padding(.horizontal, 6)
    }
}

private struct DifficultyButton: View {
    let difficulty: ExerciseReferenceOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isSelected ? AppColors.primary.opacity(0.16) : AppColors.surfaceBright.opacity(0.22))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(isSelected ? AppColors.primary : AppColors.outlineVariant.opacity(0.58), lineWidth: 1.4)
                        )

                    Image(systemName: difficulty.iconSystemName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(isSelected ? AppColors.primary : AppColors.onSurfaceVariant.opacity(0.82))
                        .rotationEffect(difficulty.isAdvanced ? .degrees(45) : .degrees(0))
                }
                .frame(width: 42, height: 42)

                Text(difficulty.shortDisplayName)
                    .font(AppFonts.Body.bold(8))
                    .foregroundStyle(isSelected ? AppColors.primary : AppColors.onSurfaceVariant)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(width: 66)
        }
        .buttonStyle(.plain)
    }
}

private extension ExerciseReferenceOption {
    var shortDisplayName: String {
        switch name.lowercased() {
        case "beginner":
            return "BEG"
        case "advanced":
            return "ADV"
        default:
            return name.uppercased()
        }
    }

    var isAdvanced: Bool {
        name.localizedCaseInsensitiveContains("advanced") || name.localizedCaseInsensitiveContains("adv")
    }

    var iconSystemName: String {
        if name.localizedCaseInsensitiveContains("beginner") || name.localizedCaseInsensitiveContains("beg") {
            return "triangle"
        }

        if isAdvanced {
            return "triangle.fill"
        }

        return "righttriangle.fill"
    }
}

private struct FlowLayout: Layout {
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

    private func rows(for subviews: Subviews, proposalWidth: CGFloat?) -> [FlowRow] {
        let maxWidth = proposalWidth ?? .infinity
        var rows: [FlowRow] = []
        var current = FlowRow()

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let proposedWidth = current.width == 0 ? size.width : current.width + spacing + size.width

            if proposedWidth > maxWidth, !current.indices.isEmpty {
                rows.append(current)
                current = FlowRow()
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

private struct FlowRow {
    var indices: [Int] = []
    var width: CGFloat = 0
    var height: CGFloat = 0
}

#Preview {
    CustomExerciseView()
}
