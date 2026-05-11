//
//  ProfileView.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import PhotosUI
import SwiftUI
import UIKit

struct ProfileView: View {
    @ObservedObject private var currentUserStore: CurrentUserStore
    @State private var recentWorkouts: [WorkoutLog] = []
    @State private var personalRecordPage: PersonalRecordsPayload?
    @State private var isLoading = false
    @State private var isLoggingOut = false
    @State private var errorMessage: String?
    @State private var personalRecordsErrorMessage: String?
    @State private var logoutErrorMessage: String?
    @State private var isShowingEditInfo = false
    @State private var didLoadInitialData: Bool

    private let userService: any UserServiceProtocol
    private let workoutService: any WorkoutServiceProtocol
    private let authService: any AuthServiceProtocol
    private let onLogOut: () -> Void

    @MainActor
    init(
        initialRecentWorkouts: [WorkoutLog]? = nil,
        initialPersonalRecordPage: PersonalRecordsPayload? = nil,
        initialErrorMessage: String? = nil,
        initialPersonalRecordsErrorMessage: String? = nil,
        onLogOut: @escaping () -> Void = {}
    ) {
        self.currentUserStore = CurrentUserStore.shared
        self.userService = UserService()
        self.workoutService = WorkoutService()
        self.authService = AuthService()
        self.onLogOut = onLogOut
        _recentWorkouts = State(initialValue: initialRecentWorkouts ?? [])
        _personalRecordPage = State(initialValue: initialPersonalRecordPage)
        _errorMessage = State(initialValue: initialErrorMessage)
        _personalRecordsErrorMessage = State(initialValue: initialPersonalRecordsErrorMessage)
        _didLoadInitialData = State(initialValue: initialRecentWorkouts != nil || initialPersonalRecordPage != nil || initialErrorMessage != nil || initialPersonalRecordsErrorMessage != nil)
    }

    @MainActor
    init(
        currentUserStore: CurrentUserStore,
        initialRecentWorkouts: [WorkoutLog]? = nil,
        initialPersonalRecordPage: PersonalRecordsPayload? = nil,
        initialErrorMessage: String? = nil,
        initialPersonalRecordsErrorMessage: String? = nil,
        userService: any UserServiceProtocol = UserService(),
        workoutService: any WorkoutServiceProtocol = WorkoutService(),
        authService: any AuthServiceProtocol = AuthService(),
        onLogOut: @escaping () -> Void = {}
    ) {
        self.currentUserStore = currentUserStore
        self.userService = userService
        self.workoutService = workoutService
        self.authService = authService
        self.onLogOut = onLogOut
        _recentWorkouts = State(initialValue: initialRecentWorkouts ?? [])
        _personalRecordPage = State(initialValue: initialPersonalRecordPage)
        _errorMessage = State(initialValue: initialErrorMessage)
        _personalRecordsErrorMessage = State(initialValue: initialPersonalRecordsErrorMessage)
        _didLoadInitialData = State(initialValue: initialRecentWorkouts != nil || initialPersonalRecordPage != nil || initialErrorMessage != nil || initialPersonalRecordsErrorMessage != nil)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        header
                            .padding(.top, 22)

                        metricGrid
                            .padding(.top, 36)

                        personalRecords
                            .padding(.top, 36)

                        recentSessions
                            .padding(.top, 36)

                        logoutButton
                            .padding(.top, 56)
                            .padding(.bottom, 30)
                    }
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height, alignment: .top)
                }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.always)
                .refreshable {
                    await loadProfile()
                }
            }
            .navigationBarHidden(true)
            .background(AppColors.background.ignoresSafeArea())
        }
        .task {
            guard !didLoadInitialData else { return }
            didLoadInitialData = true
            await loadProfile()
        }
        .sheet(isPresented: $isShowingEditInfo) {
            ProfileEditUserInfoView(
                user: currentUserStore.user,
                profileImage: currentUserStore.profileImage
            )
            .presentationDetents([.large])
        }
        .alert("Unable to Log Out", isPresented: Binding(
            get: { logoutErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    logoutErrorMessage = nil
                }
            }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(logoutErrorMessage ?? "")
        }
    }
}

private extension ProfileView {
    var header: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                UserAvatarView(size: 116, image: currentUserStore.profileImage)
                    .overlay(
                        Circle()
                            .stroke(AppColors.primary, lineWidth: 4)
                    )

                Button {
                    isShowingEditInfo = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppColors.primary)
                        .frame(width: 42, height: 42)
                        .background(AppColors.surfaceBright)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit profile")
                .offset(x: 3, y: 3)
            }

            VStack(spacing: 3) {
                Text(displayName.uppercased())
                    .font(AppFonts.Headline.bold(28))
                    .foregroundStyle(AppColors.onBackground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)

                Text(subtitle)
                    .font(AppFonts.Body.bold(15))
                    .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(maxWidth: .infinity)
    }

    var metricGrid: some View {
        HStack(spacing: 14) {
            ProfileMetricCard(title: "HEIGHT", value: ProfileFormatters.profileMetricValue(heightCM), unit: "cm")
            ProfileMetricCard(title: "WEIGHT", value: ProfileFormatters.profileMetricValue(weightKG), unit: "kg")
        }
    }

    var personalRecords: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("PERSONAL RECORDS")
                    .font(AppFonts.Body.bold(14))
                    .tracking(1.5)
                    .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.86))

                Spacer()

                NavigationLink {
                    PersonalRecordsListView()
                } label: {
                    Text("VIEW ALL")
                        .font(AppFonts.Body.bold(12))
                        .foregroundStyle(AppColors.primary)
                }
                .buttonStyle(.plain)
            }

            if isLoading && personalRecordPage == nil {
                ProgressView()
                    .tint(AppColors.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 124)
            } else if let personalRecords = personalRecordPage?.personalRecords,
                      !personalRecords.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 14) {
                        ForEach(Array(personalRecords.prefix(5).enumerated()), id: \.element.id) { index, record in
                            ProfilePRCard(record: record, accent: index.isMultiple(of: 2) ? AppColors.primary : AppColors.secondary)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .scrollIndicators(.hidden)
            } else {
                Text(personalRecordsErrorMessage ?? "No personal records yet.")
                    .font(AppFonts.Body.bold(14))
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .frame(maxWidth: .infinity, minHeight: 92)
                    .background(AppColors.surfaceVariant.opacity(0.34))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    var recentSessions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("RECENT SESSIONS")
                .font(AppFonts.Body.bold(14))
                .tracking(1.5)
                .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.86))

            if isLoading && recentWorkouts.isEmpty {
                ProgressView()
                    .tint(AppColors.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
            } else if recentWorkouts.isEmpty {
                Text(errorMessage ?? "No recent sessions yet.")
                    .font(AppFonts.Body.bold(14))
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 74)
                    .background(AppColors.surfaceVariant.opacity(0.34))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                VStack(spacing: 12) {
                    ForEach(recentWorkouts.prefix(3)) { workout in
                        ProfileRecentSessionRow(workout: workout)
                    }
                }
            }
        }
    }

    var logoutButton: some View {
        Button {
            Task {
                await logOut()
            }
        } label: {
            HStack(spacing: 14) {
                if isLoggingOut {
                    ProgressView()
                        .tint(AppColors.error)
                } else {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 18, weight: .bold))
                }

                Text(isLoggingOut ? "LOGGING OUT" : "LOGOUT")
                    .font(AppFonts.Body.bold(15))
                    .tracking(3.0)
            }
            .foregroundStyle(AppColors.error)
            .frame(maxWidth: .infinity)
            .frame(height: 62)
            .background(Color(hex: "#1A0F11").opacity(0.8))
            .overlay(
                Capsule()
                    .stroke(AppColors.error.opacity(0.28), lineWidth: 1.2)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isLoggingOut)
    }

    var displayName: String {
        let name = currentUserStore.user?.displayName ?? currentUserStore.user?.username ?? "Athlete"
        return name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Athlete" : name
    }

    var subtitle: String {
        "Shredding since \(ProfileFormatters.shreddingDate(from: currentUserStore.user?.dateOfBirth) ?? "--")"
    }

    var heightCM: Double? {
        currentUserStore.user?.heightCM
    }

    var weightKG: Double? {
        currentUserStore.user?.weightKG
    }

    @MainActor
    func loadProfile() async {
        guard !isLoading else { return }

        guard let accessToken = userService.storedAccessToken(),
              !accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            errorMessage = "Please log in again to load your profile."
            return
        }

        isLoading = true
        errorMessage = nil
        personalRecordsErrorMessage = nil

        do {
            let user = try await userService.currentUser(accessToken: accessToken)
            currentUserStore.update(user: user)
        } catch {
            errorMessage = "Unable to load your profile."
        }

        do {
            let userID = currentUserStore.user?.id
            if let userID {
                recentWorkouts = Array(try await workoutService.userWorkouts(userID: userID, page: 1, accessToken: accessToken).prefix(3))
            }
        } catch {
            if recentWorkouts.isEmpty {
                errorMessage = "Unable to load recent sessions."
            }
        }

        do {
            personalRecordPage = try await userService.personalRecords(page: 1, limit: 5, accessToken: accessToken)
        } catch {
            if personalRecordPage == nil {
                personalRecordsErrorMessage = "Unable to load personal records."
            }
        }

        isLoading = false
    }

    @MainActor
    func logOut() async {
        guard !isLoggingOut else { return }

        guard let accessToken = authService.storedAccessToken(),
              !accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            currentUserStore.clear()
            onLogOut()
            return
        }

        isLoggingOut = true
        logoutErrorMessage = nil

        do {
            try await authService.logOut(accessToken: accessToken)
            currentUserStore.clear()
            onLogOut()
        } catch {
            logoutErrorMessage = "Please try again in a moment."
        }

        isLoggingOut = false
    }
}

private struct ProfileMetricCard: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(AppFonts.Body.bold(12))
                .tracking(2.2)
                .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.62))

            HStack(alignment: .lastTextBaseline, spacing: 5) {
                Text(value)
                    .font(AppFonts.Headline.bold(24))
                    .foregroundStyle(AppColors.primary)

                Text(unit)
                    .font(AppFonts.Body.bold(11))
                    .foregroundStyle(AppColors.onSurfaceVariant)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 92)
        .background(AppColors.surfaceVariant.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ProfilePRCard: View {
    let record: PersonalRecord
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(record.exerciseName.uppercased())
                .font(AppFonts.Body.bold(10))
                .tracking(1.5)
                .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.72))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(ProfileFormatters.metricValue(record.bestWeightKG))
                    .font(AppFonts.Headline.bold(28))
                    .foregroundStyle(AppColors.onBackground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.66)

                Text("kg")
                    .font(AppFonts.Body.bold(13))
                    .foregroundStyle(accent)
            }

            HStack(spacing: 5) {
                Image(systemName: "medal")
                    .font(.system(size: 10, weight: .bold))

                Text("\(record.bestReps) REPS")
                    .font(AppFonts.Body.bold(9))
                    .lineLimit(1)
            }
            .foregroundStyle(AppColors.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .frame(width: 146, height: 124, alignment: .leading)
        .background(AppColors.surfaceVariant.opacity(0.72))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(accent)
                .frame(width: 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ProfileRecentSessionRow: View {
    let workout: WorkoutLog

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(workout.title.uppercased())
                    .font(AppFonts.Headline.bold(17))
                    .foregroundStyle(AppColors.onBackground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(ProfileFormatters.shortDate(workout.startedAt))
                    .font(AppFonts.Body.bold(12))
                    .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.76))
            }

            Spacer(minLength: 12)

            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppColors.secondary)

                Text(DurationFormatters.workoutDuration(seconds: workout.durationSec, unitStyle: .compact))
                    .font(AppFonts.Body.bold(13))
                    .foregroundStyle(AppColors.onBackground)
            }
            .padding(.horizontal, 16)
            .frame(height: 34)
            .background(AppColors.surfaceBright.opacity(0.82))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 70)
        .background(AppColors.surfaceVariant.opacity(0.34))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct PersonalRecordsListView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var records: [PersonalRecord] = []
    @State private var page = 1
    @State private var totalPages = 1
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let userService: any UserServiceProtocol = UserService()
    private let pageLimit = 10

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    if let errorMessage, records.isEmpty {
                        Text(errorMessage)
                            .font(AppFonts.Body.bold(14))
                            .foregroundStyle(AppColors.onSurfaceVariant)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, minHeight: 120)
                            .background(AppColors.surfaceVariant.opacity(0.34))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else {
                        VStack(spacing: 12) {
                            ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                                PersonalRecordWideCard(
                                    record: record,
                                    accent: index.isMultiple(of: 2) ? AppColors.primary : AppColors.secondary
                                )
                            }

                            if isLoading {
                                ProgressView()
                                    .tint(AppColors.primary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                            } else if page < totalPages {
                                Button {
                                    Task {
                                        await loadRecords(reset: false)
                                    }
                                } label: {
                                    Text("LOAD MORE")
                                        .font(AppFonts.Body.bold(12))
                                        .foregroundStyle(AppColors.primary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 46)
                                }
                                .buttonStyle(.plain)
                            } else if records.isEmpty {
                                Text("No personal records yet.")
                                    .font(AppFonts.Body.bold(14))
                                    .foregroundStyle(AppColors.onSurfaceVariant)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity, minHeight: 90)
                                    .background(AppColors.surfaceVariant.opacity(0.34))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.always)
            .refreshable {
                await loadRecords(reset: true)
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadRecords(reset: true)
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
                    .frame(width: 38, height: 38, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            Text("PERSONAL RECORDS")
                .font(AppFonts.Headline.bold(24))
                .foregroundStyle(AppColors.onBackground)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Spacer()
        }
    }

    @MainActor
    private func loadRecords(reset: Bool) async {
        guard !isLoading else { return }

        guard let accessToken = userService.storedAccessToken(),
              !accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            errorMessage = "Please log in again to load personal records."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let nextPage = reset ? 1 : page + 1
            let payload = try await userService.personalRecords(page: nextPage, limit: pageLimit, accessToken: accessToken)
            records = reset ? payload.personalRecords : records + payload.personalRecords
            page = payload.pagination.page
            totalPages = max(payload.pagination.totalPages, 1)
        } catch {
            errorMessage = "Unable to load personal records."
        }

        isLoading = false
    }
}

private struct PersonalRecordWideCard: View {
    let record: PersonalRecord
    let accent: Color

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 7) {
                Text(record.exerciseName.uppercased())
                    .font(AppFonts.Headline.bold(18))
                    .foregroundStyle(AppColors.onBackground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(accent)

                    Text(ProfileFormatters.shortDate(record.updatedAt))
                        .font(AppFonts.Body.bold(12))
                        .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.76))
                }

                HStack(spacing: 7) {
                    Image(systemName: "medal")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppColors.primary)

                    Text("BEST SET")
                        .font(AppFonts.Body.bold(10))
                        .tracking(1.2)
                        .foregroundStyle(AppColors.primary)
                }
            }

            Spacer(minLength: 10)

            VStack(alignment: .trailing, spacing: 7) {
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(ProfileFormatters.metricValue(record.bestWeightKG))
                        .font(AppFonts.Headline.bold(34))
                        .foregroundStyle(AppColors.onBackground)
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)

                    Text("kg")
                        .font(AppFonts.Body.bold(13))
                        .foregroundStyle(accent)
                }

                HStack(spacing: 8) {
                    PRValuePill(label: "\(record.bestReps) reps")
                    PRValuePill(label: "1RM \(ProfileFormatters.metricValue(record.estimated1RM))kg")
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 118)
        .background(AppColors.surfaceVariant.opacity(0.58))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(accent)
                .frame(width: 4)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct PRValuePill: View {
    let label: String

    var body: some View {
        Text(label)
            .font(AppFonts.Body.bold(11))
            .foregroundStyle(AppColors.onSurfaceVariant)
            .lineLimit(1)
            .minimumScaleFactor(0.66)
            .padding(.horizontal, 16)
            .frame(height: 26)
            .background(AppColors.surfaceBright.opacity(0.76))
            .clipShape(Capsule())
    }
}

private struct ProfileEditUserInfoView: View {
    let user: AuthenticatedUser?
    let profileImage: UIImage?

    @Environment(\.dismiss) private var dismiss
    @State private var fullName: String
    @State private var dateOfBirth: Date
    @State private var selectedGender: ProfileGender
    @State private var height: String
    @State private var weight: String
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedProfileImage: UIImage?
    @State private var profileImageData: Data?
    @State private var isSaving = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: ProfileEditField?

    private let userService: any UserServiceProtocol = UserService()

    init(user: AuthenticatedUser?, profileImage: UIImage?) {
        self.user = user
        self.profileImage = profileImage
        _fullName = State(initialValue: user?.displayName ?? user?.username ?? "")
        _dateOfBirth = State(initialValue: ProfileFormatters.date(from: user?.dateOfBirth) ?? Date())
        _selectedGender = State(initialValue: ProfileGender(apiValue: user?.gender) ?? .male)
        _height = State(initialValue: user?.heightCM.map(ProfileFormatters.editMetricValue) ?? "")
        _weight = State(initialValue: user?.weightKG.map(ProfileFormatters.editMetricValue) ?? "")
        _selectedProfileImage = State(initialValue: profileImage)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 22) {
                        avatarPicker
                            .padding(.top, 14)

                        form

                        if let errorMessage {
                            Text(errorMessage)
                                .font(AppFonts.Body.bold(13))
                                .foregroundStyle(AppColors.error)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }

                        saveButton
                            .padding(.top, 10)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 26)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("EDIT PROFILE")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppColors.onSurfaceVariant)
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
        }
        .task(id: selectedPhotoItem) {
            await loadSelectedPhoto()
        }
    }

    private var avatarPicker: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            ZStack(alignment: .bottomTrailing) {
                UserAvatarView(size: 104, image: selectedProfileImage)
                    .overlay(
                        Circle()
                            .stroke(AppColors.primary, lineWidth: 3)
                    )

                Image(systemName: "camera.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppColors.background)
                    .frame(width: 30, height: 30)
                    .background(AppColors.primary)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppColors.background, lineWidth: 2))
            }
        }
        .buttonStyle(.plain)
    }

    private var form: some View {
        VStack(spacing: 14) {
            editField(
                title: "FULL NAME",
                text: $fullName,
                keyboardType: .default,
                focusedField: .fullName
            )

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    fieldLabel("DATE OF BIRTH")

                    DatePicker("", selection: $dateOfBirth, in: ...Date(), displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .tint(AppColors.primary)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
                        .background(AppColors.surfaceVariant.opacity(0.88))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 8) {
                    fieldLabel("GENDER")

                    HStack(spacing: 8) {
                        ForEach(ProfileGender.allCases, id: \.self) { gender in
                            Button {
                                selectedGender = gender
                            } label: {
                                Text(gender.symbol)
                                    .font(.system(size: 21, weight: .semibold))
                                    .foregroundStyle(selectedGender == gender ? AppColors.primary : AppColors.onSurfaceVariant.opacity(0.7))
                                    .frame(width: 52, height: 54)
                                    .background(AppColors.surfaceVariant.opacity(0.88))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .stroke(selectedGender == gender ? AppColors.primary : Color.clear, lineWidth: 1.3)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                editField(
                    title: "HEIGHT",
                    text: $height,
                    unit: "CM",
                    keyboardType: .decimalPad,
                    focusedField: .height
                )

                editField(
                    title: "WEIGHT",
                    text: $weight,
                    unit: "KG",
                    keyboardType: .decimalPad,
                    focusedField: .weight
                )
            }
        }
    }

    private var saveButton: some View {
        Button {
            Task {
                await save()
            }
        } label: {
            HStack(spacing: 10) {
                Text(isSaving ? "SAVING" : "SAVE CHANGES")
                    .font(AppFonts.Body.bold(14))

                if isSaving {
                    ProgressView()
                        .tint(Color.black.opacity(0.72))
                }
            }
            .foregroundStyle(Color.black.opacity(0.78))
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(AppColors.primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
    }

    private func editField(
        title: String,
        text: Binding<String>,
        unit: String? = nil,
        keyboardType: UIKeyboardType,
        focusedField: ProfileEditField
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel(title)

            HStack(spacing: 8) {
                TextField("", text: text)
                    .font(AppFonts.Body.bold(16))
                    .foregroundStyle(AppColors.onBackground)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: focusedField)
                    .submitLabel(.done)

                if let unit {
                    Text(unit)
                        .font(AppFonts.Body.bold(11))
                        .foregroundStyle(AppColors.primary)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(AppColors.surfaceVariant.opacity(0.88))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(AppFonts.Body.bold(10))
            .tracking(1.8)
            .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.74))
    }

    @MainActor
    private func save() async {
        guard !isSaving else { return }

        guard let accessToken = userService.storedAccessToken(),
              !accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            errorMessage = "Please log in again to update your profile."
            return
        }

        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Name is required."
            return
        }

        let hasBodyMetricInput = !height.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !weight.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let heightValue = ProfileFormatters.decimalValue(from: height)
        let weightValue = ProfileFormatters.decimalValue(from: weight)

        if hasBodyMetricInput && (heightValue == nil || weightValue == nil) {
            errorMessage = "Height and weight must be valid numbers."
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            var profileImageURL: String?
            if let profileImageData {
                profileImageURL = try await userService.uploadProfileImage(profileImageData, accessToken: accessToken)
            }

            let request = UpdateProfileRequest(
                displayName: trimmedName != originalDisplayName ? trimmedName : nil,
                gender: selectedGender.apiValue != originalGender ? selectedGender.apiValue : nil,
                dateOfBirth: formattedDateOfBirth != originalDateOfBirth ? formattedDateOfBirth : nil,
                profileImageURL: profileImageURL
            )

            if request.hasChanges {
                try await userService.updateProfile(request, accessToken: accessToken)
            }

            if let heightValue,
               let weightValue,
               originalHeight != Optional(heightValue) || originalWeight != Optional(weightValue) {
                try await userService.updateBodyMetric(heightCM: heightValue, weightKG: weightValue, accessToken: accessToken)
            }

            if let profileImageData {
                CurrentUserStore.shared.setProfileImage(data: profileImageData, profileImageURL: profileImageURL)
            }

            _ = try await userService.refreshCurrentUser(accessToken: accessToken)
            AppDataRefreshCenter.notifyChange(.profileUpdated)
            dismiss()
        } catch {
            errorMessage = "Unable to save changes."
        }

        isSaving = false
    }

    @MainActor
    private func loadSelectedPhoto() async {
        guard let selectedPhotoItem,
              let data = try? await selectedPhotoItem.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data)
        else {
            return
        }

        let compressedData = compressedProfileImageData(from: uiImage)
        profileImageData = compressedData
        selectedProfileImage = compressedData.flatMap(UIImage.init(data:)) ?? uiImage
    }

    private func compressedProfileImageData(from image: UIImage) -> Data? {
        let maxByteCount = 1_000_000
        var workingImage = image.resizedToProfileMaxDimension(1_024)

        for _ in 0..<4 {
            var quality: CGFloat = 0.86

            while quality >= 0.42 {
                if let data = workingImage.jpegData(compressionQuality: quality),
                   data.count <= maxByteCount {
                    return data
                }

                quality -= 0.12
            }

            let nextDimension = max(workingImage.profileLongestSide * 0.78, 320)
            guard nextDimension < workingImage.profileLongestSide else { break }
            workingImage = workingImage.resizedToProfileMaxDimension(nextDimension)
        }

        return workingImage.jpegData(compressionQuality: 0.38)
    }

    private var originalDisplayName: String {
        user?.displayName ?? user?.username ?? ""
    }

    private var originalGender: String {
        user?.gender ?? ProfileGender.male.apiValue
    }

    private var originalDateOfBirth: String {
        if let date = ProfileFormatters.date(from: user?.dateOfBirth) {
            return ProfileFormatters.apiDate(from: date)
        }

        return ProfileFormatters.apiDate(from: Date())
    }

    private var originalHeight: Double? {
        user?.heightCM
    }

    private var originalWeight: Double? {
        user?.weightKG
    }

    private var formattedDateOfBirth: String {
        ProfileFormatters.apiDate(from: dateOfBirth)
    }
}

private enum ProfileEditField: Hashable {
    case fullName
    case height
    case weight
}

private enum ProfileGender: CaseIterable {
    case male
    case female

    init?(apiValue: String?) {
        switch apiValue {
        case "M":
            self = .male
        case "F":
            self = .female
        default:
            return nil
        }
    }

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

private enum ProfileFormatters {
    nonisolated static func profileMetricValue(_ value: Double?) -> String {
        guard let value else { return "--" }
        return String(format: "%.1f", value)
    }

    nonisolated static func editMetricValue(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    nonisolated static func metricValue(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }

    static func shortDate(_ isoString: String) -> String {
        guard let date = isoDate(from: isoString) else { return isoString }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    static func shreddingDate(from apiDate: String?) -> String? {
        guard let date = date(from: apiDate) else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current

        let day = calendar.component(.day, from: date)
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM, yy"

        return "\(day)\(ordinalSuffix(for: day)) \(formatter.string(from: date))"
    }

    static func date(from apiDate: String?) -> Date? {
        guard let apiDate else { return nil }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: apiDate) ?? isoDate(from: apiDate)
    }

    static func apiDate(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func decimalValue(from text: String) -> Double? {
        Double(text.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: "."))
    }

    private static func isoDate(from string: String) -> Date? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: string) {
            return date
        }

        isoFormatter.formatOptions = [.withInternetDateTime]
        return isoFormatter.date(from: string)
    }

    private static func ordinalSuffix(for day: Int) -> String {
        switch day {
        case 11, 12, 13:
            return "th"
        default:
            switch day % 10 {
            case 1:
                return "st"
            case 2:
                return "nd"
            case 3:
                return "rd"
            default:
                return "th"
            }
        }
    }
}

private extension UpdateProfileRequest {
    var hasChanges: Bool {
        displayName != nil || gender != nil || dateOfBirth != nil || profileImageURL != nil
    }
}

private extension UIImage {
    var profileLongestSide: CGFloat {
        max(size.width, size.height)
    }

    func resizedToProfileMaxDimension(_ maxDimension: CGFloat) -> UIImage {
        guard profileLongestSide > maxDimension else { return self }

        let scale = maxDimension / profileLongestSide
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

#Preview {
    ProfileView()
}
