//
//  HomeView.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import SwiftUI


struct HomeView: View {
    @State private var selectedTab: HomeTab = .workout
    @State private var homeData: HomeStartupData?
    @State private var dataGeneration = 0
    @State private var isRefreshingHomeData = false
    @ObservedObject private var currentUserStore: CurrentUserStore
    private let feedItems: [FeedActivity]? = nil
    private let startupData: HomeStartupData?
    private let onLogOut: () -> Void
    private let authService: any AuthServiceProtocol = AuthService()
    private let userService: any UserServiceProtocol = UserService()
    private let routineService: any RoutineServiceProtocol = RoutineService()
    private let workoutService: any WorkoutServiceProtocol = WorkoutService()
    private let bottomNavigationHeight: CGFloat = 64
    private let bottomNavigationBottomSpacing: CGFloat = 6
    private let contentBottomSpacing: CGFloat = 24

    @MainActor
    init(startupData: HomeStartupData? = nil, onLogOut: @escaping () -> Void = {}) {
        self.currentUserStore = CurrentUserStore.shared
        self.startupData = startupData
        self.onLogOut = onLogOut
        _homeData = State(initialValue: startupData)
    }

    init(currentUserStore: CurrentUserStore, startupData: HomeStartupData? = nil, onLogOut: @escaping () -> Void = {}) {
        self.currentUserStore = currentUserStore
        self.startupData = startupData
        self.onLogOut = onLogOut
        _homeData = State(initialValue: startupData)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HomeTopBarView(profileImage: currentUserStore.profileImage)
                    .padding(.horizontal, 16)
                    .padding(.top, 18)

                selectedContent
                    .id("\(selectedTab)-\(dataGeneration)")
            }
            .padding(.bottom, bottomNavigationHeight + bottomNavigationBottomSpacing + contentBottomSpacing)

            VStack(spacing: 0) {
                BottomNavigationBar(selectedTab: $selectedTab)
                    .padding(.horizontal, 16)

                Color.clear
                    .frame(height: bottomNavigationBottomSpacing)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onReceive(NotificationCenter.default.publisher(for: .appDataDidChange)) { _ in
            Task {
                await refreshHomeDataOnce()
            }
        }
    }

    private var activeStartupData: HomeStartupData? {
        homeData
    }

    @ViewBuilder
    private var selectedContent: some View {
        switch selectedTab {
        case .home:
            HomeFeedView(feedItems: feedItems)
        case .workout:
            WorkoutView(
                initialRoutines: activeStartupData?.workoutRoutines,
                initialErrorMessage: activeStartupData?.workoutErrorMessage
            )
        case .routine:
            RoutineView(
                initialRoutines: activeStartupData?.routineRoutines,
                initialErrorMessage: activeStartupData?.routineErrorMessage
            )
        case .analytics:
            AnalyticsView(
                initialAnalytics: activeStartupData?.analytics,
                initialWorkouts: activeStartupData?.analyticsWorkouts,
                initialErrorMessage: activeStartupData?.analyticsErrorMessage
            )
        case .profile:
            ProfileView(
                initialRecentWorkouts: activeStartupData?.recentWorkouts,
                initialPersonalRecordPage: activeStartupData?.personalRecordPage,
                initialErrorMessage: activeStartupData?.profileErrorMessage,
                initialPersonalRecordsErrorMessage: activeStartupData?.personalRecordsErrorMessage,
                onLogOut: onLogOut
            )
        }
    }

    @MainActor
    private func refreshHomeDataOnce() async {
        guard !isRefreshingHomeData else { return }

        guard let accessToken = authService.storedAccessToken(),
              !accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return
        }

        isRefreshingHomeData = true
        defer {
            isRefreshingHomeData = false
        }

        homeData = await loadHomeData(accessToken: accessToken)
        dataGeneration += 1
    }

    private func loadHomeData(accessToken: String) async -> HomeStartupData {
        var data = HomeStartupData()
        let userID = await MainActor.run { currentUserStore.user?.id }

        async let userResult: Result<AuthenticatedUser, Error> = loadResult {
            try await userService.currentUser(accessToken: accessToken)
        }
        async let workoutRoutinesResult: Result<[Routine], Error> = loadResult {
            try await routineService.routines(page: 1, accessToken: accessToken)
        }
        async let routineRoutinesResult: Result<[Routine], Error> = loadResult {
            try await routineService.routines(page: 1, accessToken: accessToken)
        }
        async let analyticsResult: Result<WorkoutAnalyticsPayload, Error> = loadResult {
            let queryRange = AnalyticsDateRangeOption.thisWeek.queryRange
            return try await workoutService.analytics(
                startDate: queryRange.startDate,
                endDate: queryRange.endDate,
                accessToken: accessToken
            )
        }
        async let recentWorkoutsResult: Result<[WorkoutLog], Error> = loadResult {
            guard let userID else { return [] }
            return try await Array(workoutService.userWorkouts(userID: userID, page: 1, accessToken: accessToken).prefix(3))
        }
        async let personalRecordsResult: Result<PersonalRecordsPayload, Error> = loadResult {
            try await userService.personalRecords(page: 1, limit: 5, accessToken: accessToken)
        }

        if case .success(let user) = await userResult {
            await MainActor.run {
                currentUserStore.update(user: user)
            }
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
            data.analyticsWorkouts = await loadAnalyticsWorkouts(userID: analytics.userID, accessToken: accessToken)
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

    private func loadAnalyticsWorkouts(userID: String, accessToken: String) async -> [WorkoutLog] {
        do {
            return try await workoutService.userWorkouts(userID: userID, page: 1, accessToken: accessToken)
        } catch {
            return []
        }
    }

    private func loadResult<Value>(_ operation: @escaping () async throws -> Value) async -> Result<Value, Error> {
        do {
            return .success(try await operation())
        } catch {
            return .failure(error)
        }
    }
}

enum HomeTab {
    case home
    case workout
    case routine
    case analytics
    case profile
}

#Preview {
    HomeView()
}
