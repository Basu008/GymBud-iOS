//
//  HomeView.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import SwiftUI


struct HomeView: View {
    @State private var selectedTab: HomeTab = .workout
    @ObservedObject private var currentUserStore: CurrentUserStore
    private let feedItems: [FeedActivity]? = nil
    private let onLogOut: () -> Void
    private let bottomNavigationHeight: CGFloat = 64
    private let bottomNavigationBottomSpacing: CGFloat = 6
    private let contentBottomSpacing: CGFloat = 24

    @MainActor
    init(onLogOut: @escaping () -> Void = {}) {
        self.currentUserStore = CurrentUserStore.shared
        self.onLogOut = onLogOut
    }

    init(currentUserStore: CurrentUserStore, onLogOut: @escaping () -> Void = {}) {
        self.currentUserStore = currentUserStore
        self.onLogOut = onLogOut
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
            .padding(.bottom, bottomNavigationHeight + bottomNavigationBottomSpacing + contentBottomSpacing)

            VStack(spacing: 0) {
                BottomNavigationBar(selectedTab: $selectedTab)
                    .padding(.horizontal, 16)

                Color.clear
                    .frame(height: bottomNavigationBottomSpacing)
            }
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
            ProfileView(onLogOut: onLogOut)
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
