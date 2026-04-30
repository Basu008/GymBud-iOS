//
//  UserInfoView.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import PhotosUI
import SwiftUI
import UIKit

struct UserInfoView: View {
    @State private var fullName = ""
    @State private var age = "24"
    @State private var selectedGender: GenderIdentity = .male
    @State private var height = "182"
    @State private var weight = "84.5"
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var attemptedSave = false

    let onSave: () -> Void

    init(onSave: @escaping () -> Void = {}) {
        self.onSave = onSave
    }

    var body: some View {
        GeometryReader { geo in
            let safeHeight = sanitizedDimension(geo.size.height)

            ZStack {
                background

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        titleSection
                            .padding(.top, 78)

                        avatarPicker
                            .frame(maxWidth: .infinity)
                            .padding(.top, 50)

                        formSection
                            .padding(.top, 48)

                        Spacer(minLength: 44)

                        saveButton
                            .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity, minHeight: safeHeight, alignment: .topLeading)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task(id: selectedPhotoItem) {
            await loadSelectedPhoto()
        }
    }
}

private extension UserInfoView {
    var background: some View {
        ZStack {
            AppColors.background

            RadialGradient(
                colors: [
                    AppColors.primary.opacity(0.08),
                    AppColors.background.opacity(0.35),
                    AppColors.background
                ],
                center: UnitPoint(x: 0.76, y: 0.38),
                startRadius: 8,
                endRadius: 210
            )

            LinearGradient(
                colors: [
                    Color.black.opacity(0.22),
                    Color.clear,
                    Color.black.opacity(0.18)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }

    var titleSection: some View {
        VStack(alignment: .leading, spacing: -3) {
            Text(AppStrings.UserInfo.titlePrefix)
                .font(AppFonts.Headline.bold(30))
                .foregroundStyle(AppColors.onBackground)

            Text(AppStrings.UserInfo.titleHighlight)
                .font(AppFonts.Headline.bold(30).italic())
                .foregroundStyle(AppColors.primary)
        }
        .shadow(color: AppColors.onBackground.opacity(0.12), radius: 1, x: 1, y: 0)
    }

    var avatarPicker: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(AppColors.surfaceVariant.opacity(0.72))
                        .frame(width: 94, height: 94)
                        .overlay(
                            Circle()
                                .stroke(AppColors.outlineVariant.opacity(0.24), lineWidth: 2)
                        )

                    if let profileImage {
                        profileImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 94, height: 94)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person")
                            .font(.system(size: 33, weight: .medium))
                            .foregroundStyle(AppColors.outlineVariant.opacity(0.48))
                    }
                }

                Image(systemName: "camera.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppColors.background)
                    .frame(width: 26, height: 26)
                    .background(AppColors.primary)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(AppColors.background, lineWidth: 2)
                    )
                    .offset(x: -3, y: -4)
            }
        }
        .buttonStyle(.plain)
    }

    var formSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            labeledTextField(
                title: AppStrings.UserInfo.fullName,
                text: $fullName,
                prompt: AppStrings.UserInfo.fullNamePlaceholder,
                keyboardType: .default,
                textContentType: .name
            )

            HStack(alignment: .top, spacing: 10) {
                labeledCompactField(
                    title: AppStrings.UserInfo.age,
                    text: $age,
                    prompt: AppStrings.UserInfo.agePlaceholder
                )

                VStack(alignment: .leading, spacing: 8) {
                    fieldLabel(AppStrings.UserInfo.genderIdentity)

                    HStack(spacing: 8) {
                        genderButton(.male)
                        genderButton(.female)
                    }
                }
            }

            HStack {
                fieldLabel(AppStrings.UserInfo.kineticMetrics)
            }
            .padding(.top, 30)

            VStack(spacing: 12) {
                metricField(
                    eyebrow: AppStrings.UserInfo.height,
                    value: $height,
                    unit: "CM",
                    iconName: "ruler",
                    errorMessage: heightError
                )

                metricField(
                    eyebrow: "\(AppStrings.UserInfo.weight) (KG)",
                    value: $weight,
                    unit: "KG",
                    iconName: "scalemass",
                    errorMessage: weightError
                )
            }
        }
    }

    var saveButton: some View {
        Button {
            attemptedSave = true
            guard isKineticMetricsValid else { return }
            onSave()
        } label: {
            HStack(spacing: 10) {
                Text(AppStrings.UserInfo.saveChanges)
                    .font(AppFonts.Headline.bold(14))

                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(Color.black.opacity(0.72))
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryFixed],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: AppColors.primaryFixed.opacity(0.24), radius: 18, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    func labeledTextField(
        title: String,
        text: Binding<String>,
        prompt: String,
        keyboardType: UIKeyboardType,
        textContentType: UITextContentType?
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel(title)

            TextField("", text: text, prompt: Text(prompt).foregroundStyle(AppColors.onSurfaceVariant.opacity(0.12)))
                .font(AppFonts.Body.bold(16))
                .foregroundStyle(AppColors.onBackground)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .padding(.horizontal, 16)
                .frame(height: 62)
                .background(AppColors.surfaceVariant.opacity(0.88))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    func labeledCompactField(title: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel(title)

            TextField("", text: text, prompt: Text(prompt).foregroundStyle(AppColors.onSurfaceVariant.opacity(0.7)))
                .font(AppFonts.Body.bold(17))
                .foregroundStyle(AppColors.onBackground)
                .keyboardType(.numberPad)
                .padding(.horizontal, 14)
                .frame(height: 54)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.surfaceVariant.opacity(0.88))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    func genderButton(_ gender: GenderIdentity) -> some View {
        Button {
            selectedGender = gender
        } label: {
            Text(gender.symbol)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(selectedGender == gender ? AppColors.primary : AppColors.onSurfaceVariant.opacity(0.72))
                .frame(width: 72, height: 54)
                .background(AppColors.surfaceVariant.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(selectedGender == gender ? AppColors.primary : Color.clear, lineWidth: 1.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    func metricField(
        eyebrow: String,
        value: Binding<String>,
        unit: String,
        iconName: String,
        errorMessage: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            metricCard(
                eyebrow: eyebrow,
                value: value,
                unit: unit,
                iconName: iconName,
                hasError: errorMessage != nil
            )

            if let errorMessage {
                Text(errorMessage)
                    .font(AppFonts.Body.medium(12))
                    .foregroundStyle(AppColors.error)
                    .padding(.leading, 8)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    func metricCard(
        eyebrow: String,
        value: Binding<String>,
        unit: String,
        iconName: String,
        hasError: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow)
                .font(AppFonts.Body.bold(9))
                .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.72))

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                TextField("", text: value)
                    .font(AppFonts.Headline.bold(40))
                    .foregroundStyle(AppColors.onBackground)
                    .keyboardType(.decimalPad)
                    .frame(width: 112)

                Text(unit)
                    .font(AppFonts.Headline.bold(15))
                    .foregroundStyle(AppColors.primary.opacity(0.58))

                Spacer()

                Image(systemName: iconName)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(hasError ? AppColors.error.opacity(0.82) : AppColors.outlineVariant.opacity(0.64))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 106)
        .background(AppColors.surfaceVariant.opacity(0.88))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(hasError ? AppColors.error.opacity(0.42) : Color.clear, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(AppFonts.Body.bold(9))
            .tracking(1.6)
            .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.82))
            .fixedSize(horizontal: false, vertical: true)
    }

    @MainActor
    func loadSelectedPhoto() async {
        guard let selectedPhotoItem,
              let data = try? await selectedPhotoItem.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data)
        else {
            return
        }

        profileImage = Image(uiImage: uiImage)
    }

    func sanitizedDimension(_ value: CGFloat) -> CGFloat {
        guard value.isFinite else { return 0 }
        return max(value, 0)
    }

    var heightError: String? {
        guard attemptedSave || !height.isEmpty else { return nil }
        guard let value = decimalValue(from: height),
              value >= 54.6,
              value <= 272
        else {
            return AppStrings.UserInfo.invalidHeightMessage
        }

        return nil
    }

    var weightError: String? {
        guard attemptedSave || !weight.isEmpty else { return nil }
        guard let value = decimalValue(from: weight),
              value >= 20,
              value <= 635
        else {
            return AppStrings.UserInfo.invalidWeightMessage
        }

        return nil
    }

    var isKineticMetricsValid: Bool {
        heightError == nil && weightError == nil
    }

    func decimalValue(from text: String) -> Double? {
        Double(text.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: "."))
    }
}

private enum GenderIdentity: CaseIterable {
    case male
    case female

    var symbol: String {
        switch self {
        case .male:
            return "♂"
        case .female:
            return "♀"
        }
    }
}

#Preview {
    UserInfoView()
}
