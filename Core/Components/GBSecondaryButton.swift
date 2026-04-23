//
//  GBSecondaryButton.swift
//  GymBud
//
//  Created by Basu Singh on 23/04/26.
//

import SwiftUI

struct GBSecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFonts.Headline.bold(18))
                .foregroundStyle(AppColors.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 72)
                .background(Color.white.opacity(0.02))
                .overlay(
                    Capsule()
                        .stroke(AppColors.primary.opacity(0.12), lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
    }
}
