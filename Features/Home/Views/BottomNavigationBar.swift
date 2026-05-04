//
//  BottomNavigationBar.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import SwiftUI

struct BottomNavigationBar: View {
    @Binding var selectedTab: HomeTab

    private let items: [BottomNavItem] = [
        // BottomNavItem(title: "HOME", icon: "house.fill", tab: .home),
        BottomNavItem(title: "LOG", icon: "square.and.pencil", tab: .workout),
        BottomNavItem(title: "ROUTINE", icon: "figure.strengthtraining.traditional", tab: .routine),
        BottomNavItem(title: "ANALYTICS", icon: "chart.line.uptrend.xyaxis", tab: .analytics),
        BottomNavItem(title: "PROFILE", icon: "person.fill", tab: .profile)
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                BottomNavigationItemView(
                    item: item,
                    isSelected: selectedTab == item.tab
                ) {
                    selectedTab = item.tab
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 64)
        .background(Color.black.opacity(0.76))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct BottomNavigationItemView: View {
    let item: BottomNavItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: item.icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(isSelected ? AppColors.primary : AppColors.onSurfaceVariant)

                Text(item.title)
                    .font(AppFonts.Body.bold(9))
                    .tracking(1.1)
                    .foregroundStyle(isSelected ? AppColors.primary : AppColors.onSurfaceVariant)
            }
            .frame(height: 56)
        }
        .buttonStyle(.plain)
    }
}

private struct BottomNavItem: Identifiable {
    var id: String { title }
    let title: String
    let icon: String
    let tab: HomeTab
}
