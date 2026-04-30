//
//  HomeView.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text("GymBud")
                    .font(AppFonts.Headline.bold(34))
                    .foregroundStyle(AppColors.onBackground)

                Text("Your dashboard is ready.")
                    .font(AppFonts.Body.medium(15))
                    .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.78))
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    HomeView()
}
