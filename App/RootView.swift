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

    @State private var path: [Route] = []

    var body: some View {
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
                        path.append(.logIn)
                    }
                case .logIn:
                    LogInView {
                        path.append(.signUp)
                    }
                }
            }
        }
    }
}

#Preview {
    RootView()
}
