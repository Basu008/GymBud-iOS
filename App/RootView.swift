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
    private let authService: any AuthServiceProtocol = AuthService()
    private let userService: any UserServiceProtocol = UserService()

    var body: some View {
        Group {
            switch appDestination {
            case .checkingSession:
                sessionLoadingView
            case .onboarding:
                authNavigationStack
            case .userInfo:
                UserInfoView {
                    appDestination = .home
                }
            case .home:
                HomeView()
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
                            appDestination = .home
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

            ProgressView()
                .tint(AppColors.primary)
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
                appDestination = .home
            }
        } catch {
            CurrentUserStore.shared.clear()
            path.removeAll()
            appDestination = .onboarding
        }
    }
}

#Preview {
    RootView()
}
