//
//  GBPrimaryButton.swift
//  GymBud
//
//  Created by Basu Singh on 23/04/26.
//

import SwiftUI

struct GBPrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFonts.Headline.bold(18))
                .foregroundStyle(Color.black.opacity(0.78))
                .frame(maxWidth: .infinity)
                .frame(height: 72)
                .background(
                    LinearGradient(
                        colors: [AppColors.primary.opacity(0.9), AppColors.primaryFixed],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: AppColors.primary.opacity(0.18), radius: 16, x: 0, y: 8)
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
    }
}
