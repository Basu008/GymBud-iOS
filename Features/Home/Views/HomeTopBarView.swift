//
//  HomeTopBarView.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import SwiftUI
import UIKit

struct HomeTopBarView: View {
    let profileImage: UIImage?

    var body: some View {
        HStack(spacing: 9) {
            UserAvatarView(size: 29, image: profileImage)

            Text("GYMBUD")
                .font(AppFonts.Headline.bold(15))
                .foregroundStyle(AppColors.onBackground)

            Spacer()

            Button {} label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
        }
        .frame(height: 34)
    }
}
