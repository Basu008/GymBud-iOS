//
//  LogInView.swift
//  GymBud
//
//  Created by Codex on 29/04/26.
//

import SwiftUI

struct LogInView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var attemptedSubmit = false
    let onCreateAccount: () -> Void

    init(onCreateAccount: @escaping () -> Void = {}) {
        self.onCreateAccount = onCreateAccount
    }

    var body: some View {
        GeometryReader { geo in
            let safeHeight = sanitizedDimension(geo.size.height)

            ZStack(alignment: .top) {
                AppColors.background
                    .ignoresSafeArea()

                heroBackground(height: min(max(safeHeight * 0.28, 0), 220))

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.1),
                        Color.black.opacity(0.48),
                        AppColors.background,
                        AppColors.background
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    titleSection
                        .padding(.top, 24)
                        .padding(.horizontal, 24)

                    formSection
                        .padding(.top, 18)
                        .padding(.horizontal, 24)

                    Spacer(minLength: 24)

                    VStack(spacing: 14) {
                        primaryButton
                            .padding(.horizontal, 24)

                        footer
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.bottom, 36)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }
}

private extension LogInView {
    var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppStrings.LogIn.title)
                .font(AppFonts.Headline.bold(30))
                .foregroundStyle(AppColors.onBackground)
                .lineSpacing(-2)
                .fixedSize(horizontal: false, vertical: true)

            Text(AppStrings.LogIn.subtitle)
                .font(AppFonts.Body.medium(16))
                .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.92))
                .lineSpacing(4)
                .frame(maxWidth: 260, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    var formSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            labeledField(
                title: AppStrings.LogIn.username,
                text: $username,
                prompt: AppStrings.LogIn.usernamePlaceholder,
                leadingSystemImage: "person.crop.circle",
                trailingSystemImage: usernameError == nil ? nil : "exclamationmark.circle",
                trailingColor: AppColors.error,
                isSecure: false,
                errorMessage: usernameError
            )

            labeledField(
                title: AppStrings.LogIn.password,
                text: $password,
                prompt: AppStrings.LogIn.passwordPlaceholder,
                leadingSystemImage: "lock",
                trailingSystemImage: passwordError == nil ? "eye.slash" : "exclamationmark.circle",
                trailingColor: passwordError == nil ? AppColors.primary : AppColors.error,
                isSecure: true,
                errorMessage: passwordError
            )
        }
    }

    var primaryButton: some View {
        Button {
            attemptedSubmit = true
        } label: {
            Text(AppStrings.LogIn.primaryButtonTitle)
                .font(AppFonts.Headline.bold(18))
                .foregroundStyle(Color.black.opacity(0.78))
                .frame(maxWidth: .infinity)
                .frame(height: 72)
                .background(
                    LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryFixed],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: AppColors.primary.opacity(0.22), radius: 18, x: 0, y: 10)
        }
        .buttonStyle(.plain)
    }

    var footer: some View {
        HStack(spacing: 6) {
            Text(AppStrings.LogIn.footerPrefix)
                .font(AppFonts.Body.medium(14))
                .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.78))

            Button(AppStrings.LogIn.footerActionTitle) {
                onCreateAccount()
            }
                .font(AppFonts.Body.bold(14))
                .foregroundStyle(AppColors.primary)
                .buttonStyle(.plain)
        }
    }

    func labeledField(
        title: String,
        text: Binding<String>,
        prompt: String,
        leadingSystemImage: String,
        trailingSystemImage: String?,
        trailingColor: Color,
        isSecure: Bool,
        errorMessage: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFonts.Body.bold(12))
                .tracking(2)
                .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Image(systemName: leadingSystemImage)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppColors.secondary)
                    .frame(width: 20)

                if isSecure {
                    SecureField("", text: text, prompt: Text(prompt).foregroundStyle(AppColors.onSurfaceVariant.opacity(0.45)))
                        .font(AppFonts.Body.semibold(16))
                        .foregroundStyle(AppColors.onBackground)
                        .textInputAutocapitalization(.never)
                } else {
                    TextField("", text: text, prompt: Text(prompt).foregroundStyle(AppColors.onSurfaceVariant.opacity(0.45)))
                        .font(AppFonts.Body.semibold(16))
                        .foregroundStyle(AppColors.onBackground)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                if let trailingSystemImage {
                    Image(systemName: trailingSystemImage)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(trailingColor)
                }
            }
            .padding(.horizontal, 18)
            .frame(height: 46)
            .background(AppColors.surfaceVariant.opacity(0.98))
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(errorMessage == nil ? Color.clear : AppColors.error.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))

            if let errorMessage {
                Text(errorMessage)
                    .font(AppFonts.Body.medium(12))
                    .foregroundStyle(AppColors.error)
                    .padding(.leading, 8)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    func heroBackground(height: CGFloat) -> some View {
        Image(AppImages.onboardingBackground)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipped()
            .overlay(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.15),
                        Color.black.opacity(0.46),
                        AppColors.background.opacity(0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .ignoresSafeArea(edges: .top)
    }

    func sanitizedDimension(_ value: CGFloat) -> CGFloat {
        guard value.isFinite else { return 0 }
        return max(value, 0)
    }

    var usernameError: String? {
        guard attemptedSubmit || !username.isEmpty else { return nil }
        return username.count >= 4 ? nil : AppStrings.LogIn.invalidUsernameMessage
    }

    var passwordError: String? {
        guard attemptedSubmit || !password.isEmpty else { return nil }
        return password.count >= 8 ? nil : AppStrings.LogIn.invalidPasswordMessage
    }
}

#Preview {
    LogInView()
}
