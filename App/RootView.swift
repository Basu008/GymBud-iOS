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
    }

    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            OnboardingView {
                path.append(.signUp)
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .signUp:
                    SignUpView()
                }
            }
        }
    }
}

#Preview {
    RootView()
}
