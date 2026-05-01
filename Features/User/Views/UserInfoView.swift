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
    @StateObject private var viewModel: UserInfoViewModel
    @State private var fullName = ""
    @State private var dateOfBirth = Calendar.current.date(from: DateComponents(year: 1990, month: 10, day: 5)) ?? Date()
    @State private var selectedGender: GenderIdentity = .male
    @State private var height = "182"
    @State private var weight = "84.5"
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var profileImageData: Data?
    @State private var attemptedSave = false
    @FocusState private var focusedField: UserInfoField?

    let onSave: () -> Void

    @MainActor
    init(onSave: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: UserInfoViewModel())
        self.onSave = onSave
    }

    @MainActor
    init(
        viewModel: UserInfoViewModel,
        onSave: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
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
                            .padding(.top, 42)

                        avatarPicker
                            .frame(maxWidth: .infinity)
                            .padding(.top, 22)

                        formSection
                            .padding(.top, 28)

                        Spacer(minLength: 20)

                        saveButton
                            .padding(.bottom, 16)
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
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button(AppStrings.UserInfo.keyboardDone) {
                    focusedField = nil
                }
            }
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
                .font(AppFonts.Headline.bold(28))
                .foregroundStyle(AppColors.onBackground)

            Text(AppStrings.UserInfo.titleHighlight)
                .font(AppFonts.Headline.bold(28).italic())
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
                        .frame(width: 78, height: 78)
                        .overlay(
                            Circle()
                                .stroke(AppColors.outlineVariant.opacity(0.24), lineWidth: 2)
                        )

                    if let profileImage {
                        profileImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 78, height: 78)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person")
                            .font(.system(size: 29, weight: .medium))
                            .foregroundStyle(AppColors.outlineVariant.opacity(0.48))
                    }
                }

                Image(systemName: "camera.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppColors.background)
                    .frame(width: 24, height: 24)
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
        VStack(alignment: .leading, spacing: 12) {
            labeledTextField(
                title: AppStrings.UserInfo.fullName,
                text: $fullName,
                prompt: AppStrings.UserInfo.fullNamePlaceholder,
                keyboardType: .default,
                textContentType: .name,
                focusedField: .fullName
            )

            HStack(alignment: .top, spacing: 10) {
                dateOfBirthField

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
            .padding(.top, 12)

            VStack(spacing: 8) {
                metricField(
                    eyebrow: AppStrings.UserInfo.height,
                    value: $height,
                    unit: "CM",
                    iconName: "ruler",
                    focusedField: .height,
                    errorMessage: heightError
                )

                metricField(
                    eyebrow: "\(AppStrings.UserInfo.weight) (KG)",
                    value: $weight,
                    unit: "KG",
                    iconName: "scalemass",
                    focusedField: .weight,
                    errorMessage: weightError
                )
            }
        }
    }

    var dateOfBirthField: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel(AppStrings.UserInfo.dateOfBirth)

            DatePicker(
                "",
                selection: $dateOfBirth,
                in: ...Date(),
                displayedComponents: .date
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .tint(AppColors.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .frame(height: 50)
            .background(AppColors.surfaceVariant.opacity(0.88))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    var saveButton: some View {
        Button {
            Task {
                await saveUserInfo()
            }
        } label: {
            HStack(spacing: 10) {
                Text(viewModel.isSaving ? AppStrings.UserInfo.savingChanges : AppStrings.UserInfo.saveChanges)
                    .font(AppFonts.Headline.bold(14))

                if viewModel.isSaving {
                    ProgressView()
                        .tint(Color.black.opacity(0.72))
                } else {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                }
            }
            .foregroundStyle(Color.black.opacity(0.72))
            .frame(maxWidth: .infinity)
            .frame(height: 56)
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
        .disabled(viewModel.isSaving)
        .buttonStyle(.plain)
        .overlay(alignment: .top) {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(AppFonts.Body.medium(12))
                    .foregroundStyle(AppColors.error)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .offset(y: -32)
            }
        }
    }

    func labeledTextField(
        title: String,
        text: Binding<String>,
        prompt: String,
        keyboardType: UIKeyboardType,
        textContentType: UITextContentType?,
        focusedField: UserInfoField
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
                .focused($focusedField, equals: focusedField)
                .submitLabel(.done)
                .onSubmit {
                    self.focusedField = nil
                }
                .padding(.horizontal, 16)
                .frame(height: 54)
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
                .frame(width: 68, height: 50)
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
        focusedField: UserInfoField,
        errorMessage: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            metricCard(
                eyebrow: eyebrow,
                value: value,
                unit: unit,
                iconName: iconName,
                focusedField: focusedField,
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
        focusedField: UserInfoField,
        hasError: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(eyebrow)
                .font(AppFonts.Body.bold(9))
                .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.72))

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                TextField("", text: value)
                    .font(AppFonts.Headline.bold(32))
                    .foregroundStyle(AppColors.onBackground)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: focusedField)
                    .submitLabel(.done)
                    .onSubmit {
                        self.focusedField = nil
                    }
                    .frame(width: 104)

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
        .frame(height: 82)
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

        let compressedImageData = compressedProfileImageData(from: uiImage)
        profileImage = compressedImageData
            .flatMap(UIImage.init(data:))
            .map(Image.init(uiImage:)) ?? Image(uiImage: uiImage)
        profileImageData = compressedImageData
    }

    func compressedProfileImageData(from image: UIImage) -> Data? {
        let maxByteCount = 1_000_000
        let maxInitialDimension: CGFloat = 1_024
        var workingImage = image.resizedToFit(maxDimension: maxInitialDimension)

        for _ in 0..<4 {
            var quality: CGFloat = 0.86

            while quality >= 0.42 {
                if let data = workingImage.jpegData(compressionQuality: quality),
                   data.count <= maxByteCount {
                    return data
                }

                quality -= 0.12
            }

            let nextDimension = max(workingImage.longestSide * 0.78, 320)
            guard nextDimension < workingImage.longestSide else { break }
            workingImage = workingImage.resizedToFit(maxDimension: nextDimension)
        }

        var fallbackQuality: CGFloat = 0.38
        while let data = workingImage.jpegData(compressionQuality: fallbackQuality) {
            if data.count <= maxByteCount {
                return data
            }

            if fallbackQuality > 0.24 {
                fallbackQuality -= 0.06
            } else if workingImage.longestSide > 120 {
                workingImage = workingImage.resizedToFit(maxDimension: workingImage.longestSide * 0.72)
            } else {
                return data
            }
        }

        return nil
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

    @MainActor
    func saveUserInfo() async {
        attemptedSave = true
        viewModel.errorMessage = nil

        guard isKineticMetricsValid,
              let heightValue = decimalValue(from: height),
              let weightValue = decimalValue(from: weight)
        else {
            return
        }

        let didSave = await viewModel.saveUserInfo(
            displayName: fullName,
            gender: selectedGender.apiValue,
            dateOfBirth: formattedDateOfBirth,
            heightCM: heightValue,
            weightKG: weightValue,
            profileImageData: profileImageData
        )

        if didSave {
            onSave()
        }
    }

    var formattedDateOfBirth: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: dateOfBirth)
    }

    func decimalValue(from text: String) -> Double? {
        Double(text.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: "."))
    }
}

private enum UserInfoField: Hashable {
    case fullName
    case height
    case weight
}

private extension UIImage {
    var longestSide: CGFloat {
        max(size.width, size.height)
    }

    func resizedToFit(maxDimension: CGFloat) -> UIImage {
        guard longestSide > maxDimension else { return self }

        let scale = maxDimension / longestSide
        let targetSize = CGSize(
            width: size.width * scale,
            height: size.height * scale
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
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

    var apiValue: String {
        switch self {
        case .male:
            return "M"
        case .female:
            return "F"
        }
    }
}

#Preview {
    UserInfoView()
}
