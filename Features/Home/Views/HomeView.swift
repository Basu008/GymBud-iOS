//
//  HomeView.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import SwiftUI


struct HomeView: View {
    @State private var selectedTab: HomeTab = .home
    @ObservedObject private var currentUserStore: CurrentUserStore
    private let feedItems: [FeedActivity]? = nil

    @MainActor
    init() {
        self.currentUserStore = CurrentUserStore.shared
    }

    init(currentUserStore: CurrentUserStore) {
        self.currentUserStore = currentUserStore
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
            }
            .padding(.bottom, 78)

            BottomNavigationBar(selectedTab: $selectedTab)
                .padding(.horizontal, 9)
                .padding(.bottom, 0)
        }
        .navigationBarBackButtonHidden(true)
    }

    @ViewBuilder
    private var selectedContent: some View {
        switch selectedTab {
        case .home:
            HomeFeedView(feedItems: feedItems)
        case .workout:
            WorkoutView()
        case .routine:
            RoutineView()
        case .analytics:
            AnalyticsView()
        case .profile:
            ProfileView()
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
