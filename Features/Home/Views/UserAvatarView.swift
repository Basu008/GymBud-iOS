//
//  UserAvatarView.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import SwiftUI
import UIKit

struct UserAvatarView: View {
    let size: CGFloat
    var image: UIImage? = nil

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            AppColors.secondary.opacity(0.72),
                            AppColors.surfaceBright,
                            AppColors.primary.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.48, weight: .semibold))
                    .foregroundStyle(AppColors.onBackground.opacity(0.86))
            }
        }
        .frame(width: size, height: size)
        .overlay(
            Circle()
                .stroke(AppColors.onBackground.opacity(0.9), lineWidth: 1)
        )
    }
}
