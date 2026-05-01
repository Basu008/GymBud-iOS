//
//  PlaceholderSectionView.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import SwiftUI

struct PlaceholderSectionView: View {
    let title: String

    var body: some View {
        VStack {
            Spacer()

            Text(title)
                .font(AppFonts.Headline.bold(28))
                .foregroundStyle(AppColors.onBackground)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
