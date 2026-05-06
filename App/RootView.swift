//
//  RootView.swift
//  GymBud
//
//  Created by Basu Singh on 23/04/26.
//

import SwiftUI

struct RootView: View {
    private enum Route: Hashable {
        case signUp
        case logIn
    }

    private enum AppDestination {
        case checkingSession
        case onboarding
        case userInfo
        case home
    }

    @State private var path: [Route] = []
    @State private var didCheckStoredSession = false
    @State private var appDestination: AppDestination = .checkingSession
    @State private var homeStartupData: HomeStartupData?
    private let authService: any AuthServiceProtocol = AuthService()
    private let userService: any UserServiceProtocol = UserService()
    private let routineService: any RoutineServiceProtocol = RoutineService()
    private let workoutService: any WorkoutServiceProtocol = WorkoutService()

    var body: some View {
        Group {
            switch appDestination {
            case .checkingSession:
                sessionLoadingView
            case .onboarding:
                authNavigationStack
            case .userInfo:
                UserInfoView {
                    showHomeAfterSplash()
                }
            case .home:
                HomeView(startupData: homeStartupData) {
                    CurrentUserStore.shared.clear()
                    homeStartupData = nil
                    path.removeAll()
                    appDestination = .onboarding
                }
            }
        }
        .task {
            await restoreStoredSessionIfNeeded()
        }
    }
}

private extension RootView {
    var authNavigationStack: some View {
        NavigationStack(path: $path) {
            OnboardingView(
                onGetStarted: {
                    path.append(.signUp)
                },
                onSignIn: {
                    path.append(.logIn)
                }
            )
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .signUp:
                    SignUpView {
                        path = [.logIn]
                    }
                case .logIn:
                    LogInView(
                        onCreateAccount: {
                            path = [.signUp]
                        },
                        onNeedsUserInfo: {
                            path.removeAll()
                            appDestination = .userInfo
                        },
                        onLogInComplete: {
                            path.removeAll()
                            showHomeAfterSplash()
                        }
                    )
                }
            }
        }
    }

    var sessionLoadingView: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            Image("LaunchLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 260, height: 260)
        }
    }

    func showHomeAfterSplash() {
        appDestination = .checkingSession

        Task {
            await prepareHomeAndShow()
        }
    }

    @MainActor
    func restoreStoredSessionIfNeeded() async {
        guard !didCheckStoredSession else { return }
        didCheckStoredSession = true

        guard let accessToken = authService.storedAccessToken(),
              !accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            appDestination = .onboarding
            return
        }

        do {
            let user = try await userService.currentUser(accessToken: accessToken)
            CurrentUserStore.shared.update(user: user)

            if user.needsUserInfo {
                appDestination = .userInfo
            } else {
                await prepareHomeAndShow()
            }
        } catch {
            CurrentUserStore.shared.clear()
            path.removeAll()
            appDestination = .onboarding
        }
    }

    @MainActor
    func prepareHomeAndShow() async {
        guard let accessToken = authService.storedAccessToken(),
              !accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            appDestination = .onboarding
            return
        }

        homeStartupData = await loadHomeStartupData(accessToken: accessToken)
        appDestination = .home
    }

    func loadHomeStartupData(accessToken: String) async -> HomeStartupData {
        var data = HomeStartupData()
        let userID = await MainActor.run { CurrentUserStore.shared.user?.id }

        async let workoutRoutinesResult: Result<[Routine], Error> = loadResult {
            try await routineService.routines(page: 1, accessToken: accessToken)
        }
        async let routineRoutinesResult: Result<[Routine], Error> = loadResult {
            try await routineService.routines(page: 1, accessToken: accessToken)
        }
        async let analyticsResult: Result<WorkoutAnalyticsPayload, Error> = loadResult {
            try await workoutService.analytics(accessToken: accessToken)
        }
        async let recentWorkoutsResult: Result<[WorkoutLog], Error> = loadResult {
            guard let userID else { return [] }
            return try await Array(workoutService.userWorkouts(userID: userID, page: 1, accessToken: accessToken).prefix(3))
        }
        async let personalRecordsResult: Result<PersonalRecordsPayload, Error> = loadResult {
            try await userService.personalRecords(page: 1, limit: 5, accessToken: accessToken)
        }

        switch await workoutRoutinesResult {
        case .success(let routines):
            data.workoutRoutines = routines
        case .failure:
            data.workoutErrorMessage = "Unable to load routines."
        }

        switch await routineRoutinesResult {
        case .success(let routines):
            data.routineRoutines = routines
        case .failure:
            data.routineErrorMessage = "Unable to load routines."
        }

        switch await analyticsResult {
        case .success(let analytics):
            data.analytics = analytics
            data.analyticsWorkouts = await loadAnalyticsWorkouts(
                userID: analytics.userID,
                accessToken: accessToken
            )
        case .failure:
            data.analyticsErrorMessage = "Unable to load analytics."
        }

        switch await recentWorkoutsResult {
        case .success(let workouts):
            data.recentWorkouts = workouts
        case .failure:
            data.profileErrorMessage = "Unable to load recent sessions."
        }

        switch await personalRecordsResult {
        case .success(let page):
            data.personalRecordPage = page
        case .failure:
            data.personalRecordsErrorMessage = "Unable to load personal records."
        }

        return data
    }

    func loadAnalyticsWorkouts(userID: String, accessToken: String) async -> [WorkoutLog] {
        do {
            return try await workoutService.userWorkouts(userID: userID, page: 1, accessToken: accessToken)
        } catch {
            return []
        }
    }

    func loadResult<Value>(_ operation: @escaping () async throws -> Value) async -> Result<Value, Error> {
        do {
            return .success(try await operation())
        } catch {
            return .failure(error)
        }
    }
}

#Preview {
    RootView()
}
