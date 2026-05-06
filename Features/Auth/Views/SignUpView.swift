//
//  SignUpView.swift
//  GymBud
//
//  Created by Codex on 29/04/26.
//

import SwiftUI

struct SignUpView: View {
    @StateObject private var viewModel: SignUpViewModel
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var attemptedSubmit = false
    let onSignIn: () -> Void

    @MainActor
    init(onSignIn: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: SignUpViewModel())
        self.onSignIn = onSignIn
    }

    var body: some View {
        GeometryReader { geo in
            let safeHeight = sanitizedDimension(geo.size.height)

            ZStack(alignment: .top) {
                AppColors.background
                    .ignoresSafeArea()

                heroBackground(height: min(max(safeHeight * 0.28, 0), 220))

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        titleSection
                            .padding(.top, 24)
                            .padding(.horizontal, 16)

                        formSection
                            .padding(.top, 18)
                            .padding(.horizontal, 16)

                        Spacer(minLength: 24)

                        VStack(spacing: 14) {
                            createAccountButton
                                .padding(.horizontal, 16)

                            footer
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 36)
                    }
                    .frame(maxWidth: .infinity, minHeight: safeHeight, alignment: .topLeading)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

private extension SignUpView {
    var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppStrings.SignUp.title)
                .font(AppFonts.Headline.bold(30))
                .foregroundStyle(AppColors.onBackground)
                .lineSpacing(-2)
                .fixedSize(horizontal: false, vertical: true)

            Text(AppStrings.SignUp.subtitle)
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
                title: AppStrings.SignUp.username,
                text: $username,
                prompt: "alex_ironside",
                leadingSystemImage: "person.crop.circle",
                trailingSystemImage: usernameError == nil ? nil : "exclamationmark.circle",
                trailingColor: AppColors.error,
                isSecure: false,
                keyboardType: .asciiCapable,
                textContentType: .username,
                errorMessage: usernameError
            )

            labeledField(
                title: AppStrings.SignUp.email,
                text: $email,
                prompt: "alex.iron@performance.com",
                leadingSystemImage: "envelope",
                trailingSystemImage: emailError == nil ? nil : "at.circle",
                trailingColor: AppColors.error,
                isSecure: false,
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                errorMessage: emailError
            )

            VStack(alignment: .leading, spacing: 10) {
                labeledField(
                    title: AppStrings.SignUp.password,
                    text: $password,
                    prompt: "Enter password",
                    leadingSystemImage: "lock",
                    trailingSystemImage: "eye.slash",
                    trailingColor: AppColors.primary,
                    isSecure: true,
                    keyboardType: .asciiCapable,
                    textContentType: .newPassword,
                    errorMessage: passwordError
                )

                HStack(spacing: 8) {
                    Text("STRENGTH: \(passwordStrength.label)")
                        .font(AppFonts.Body.bold(13))
                        .tracking(1.2)
                        .foregroundStyle(passwordStrength.color)

                    Spacer()

                    ForEach(0..<4, id: \.self) { index in
                        Capsule()
                            .fill(index < passwordStrength.level ? passwordStrength.color : AppColors.surfaceBright)
                            .frame(width: 30, height: 5)
                            .shadow(
                                color: index < passwordStrength.level ? passwordStrength.color.opacity(0.55) : .clear,
                                radius: 5,
                                x: 0,
                                y: 0
                            )
                    }
                }
            }

            labeledField(
                title: AppStrings.SignUp.confirmPassword,
                text: $confirmPassword,
                prompt: "Confirm password",
                leadingSystemImage: "checkmark.shield",
                trailingSystemImage: confirmPasswordTrailingIcon,
                trailingColor: confirmPasswordTrailingColor,
                isSecure: true,
                keyboardType: .asciiCapable,
                textContentType: .newPassword,
                errorMessage: confirmPasswordError
            )

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(AppFonts.Body.medium(12))
                    .foregroundStyle(AppColors.error)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 16)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let successMessage = viewModel.successMessage {
                Text(successMessage)
                    .font(AppFonts.Body.medium(12))
                    .foregroundStyle(AppColors.success)
                    .padding(.leading, 16)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    var createAccountButton: some View {
        Button {
            attemptedSubmit = true
            guard isFormValid else { return }

            Task {
                await viewModel.signUp(
                    username: username,
                    password: password,
                    email: email
                )

                guard viewModel.didSignUp else { return }

                try? await Task.sleep(for: .seconds(1))
                onSignIn()
            }
        } label: {
            Text(createAccountButtonTitle)
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
        .disabled(viewModel.isLoading)
        .opacity(viewModel.isLoading ? 0.72 : 1)
    }

    var footer: some View {
        HStack(spacing: 6) {
            Text(AppStrings.SignUp.existingAccount)
                .font(AppFonts.Body.medium(14))
                .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.78))

            Button(AppStrings.SignUp.signIn) {
                onSignIn()
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
        keyboardType: UIKeyboardType,
        textContentType: UITextContentType?,
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
                        .autocorrectionDisabled()
                        .keyboardType(keyboardType)
                        .textContentType(textContentType)
                } else {
                    TextField("", text: text, prompt: Text(prompt).foregroundStyle(AppColors.onSurfaceVariant.opacity(0.45)))
                        .font(AppFonts.Body.semibold(16))
                        .foregroundStyle(AppColors.onBackground)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(keyboardType)
                        .textContentType(textContentType)
                }

                if let trailingSystemImage {
                    Image(systemName: trailingSystemImage)
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(trailingColor)
                }
            }
            .padding(.horizontal, 16)
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
                    .padding(.leading, 16)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    func heroBackground(height: CGFloat) -> some View {
        LinearGradient(
            colors: [
                Color.black,
                AppColors.background
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .ignoresSafeArea(edges: .top)
    }

    func sanitizedDimension(_ value: CGFloat) -> CGFloat {
        guard value.isFinite else { return 0 }
        return max(value, 0)
    }

    var usernameError: String? {
        guard attemptedSubmit || !username.isEmpty else { return nil }
        return username.count >= 4 ? nil : "Username must be at least 4 characters"
    }

    var emailError: String? {
        guard attemptedSubmit || !email.isEmpty else { return nil }
        return email.contains("@") && email.contains(".") ? nil : "Enter a valid email address"
    }

    var confirmPasswordError: String? {
        guard attemptedSubmit || !confirmPassword.isEmpty else { return nil }
        return confirmPassword == password && !confirmPassword.isEmpty ? nil : "Passwords do not match"
    }

    var confirmPasswordTrailingIcon: String? {
        if let _ = confirmPasswordError {
            return "exclamationmark.arrow.trianglehead.counterclockwise.rotate.90"
        }

        if !confirmPassword.isEmpty && confirmPassword == password {
            return "checkmark.circle"
        }

        return nil
    }

    var confirmPasswordTrailingColor: Color {
        confirmPasswordError == nil ? AppColors.primary : AppColors.error
    }

    var passwordStrength: PasswordStrength {
        PasswordStrength(password: password)
    }

    var createAccountButtonTitle: String {
        if viewModel.didSignUp {
            return AppStrings.SignUp.accountCreated
        }

        if viewModel.isLoading {
            return AppStrings.SignUp.creatingAccount
        }

        return AppStrings.SignUp.createAccount
    }

    var passwordError: String? {
        guard attemptedSubmit || !password.isEmpty else { return nil }
        return password.count >= 8 ? nil : "Password must be at least 8 characters"
    }

    var isFormValid: Bool {
        usernameError == nil
            && emailError == nil
            && passwordError == nil
            && confirmPasswordError == nil
    }
}

private struct PasswordStrength {
    let level: Int
    let label: String
    let color: Color

    init(password: String) {
        let checks = [
            password.count >= 8,
            password.rangeOfCharacter(from: .uppercaseLetters) != nil,
            password.rangeOfCharacter(from: .decimalDigits) != nil,
            password.rangeOfCharacter(from: CharacterSet.punctuationCharacters.union(.symbols)) != nil
        ]

        level = max(checks.filter { $0 }.count, password.isEmpty ? 0 : 1)

        switch level {
        case 4:
            label = "STRONG"
            color = AppColors.success
        case 3:
            label = "GOOD"
            color = AppColors.primary
        case 2:
            label = "FAIR"
            color = Color(hex: "#F0D36A")
        case 1:
            label = "WEAK"
            color = AppColors.error
        default:
            label = "EMPTY"
            color = AppColors.surfaceBright
        }
    }
}

#Preview {
    SignUpView()
}
