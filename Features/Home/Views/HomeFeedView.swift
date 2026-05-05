//
//  HomeFeedView.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import SwiftUI

struct HomeFeedView: View {
    let feedItems: [FeedActivity]?

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("SOCIAL FEED")
                        .font(AppFonts.Headline.bold(25))
                        .foregroundStyle(AppColors.onBackground)
                        .padding(.top, 24)

                    if let feedItems {
                        ForEach(feedItems) { item in
                            FeedCardView(activity: item)
                        }
                    } else {
                        FollowPeopleEmptyView()
                            .padding(.top, emptyCardTopPadding(for: geometry.size.height))
                    }
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height, alignment: .top)
            }
            .scrollIndicators(.hidden)
        }
        .background(AppColors.background.ignoresSafeArea())
    }

    private func emptyCardTopPadding(for height: CGFloat) -> CGFloat {
        max((height - 430) / 2, 18)
    }
}

private struct FeedCardView: View {
    let activity: FeedActivity

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 10) {
                UserAvatarView(size: 38)

                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.athleteName)
                        .font(AppFonts.Body.bold(12))
                        .foregroundStyle(AppColors.onBackground)

                    Text(activity.timestamp)
                        .font(AppFonts.Body.bold(8))
                        .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.82))
                }

                Spacer()

                if activity.isPR {
                    PRBadgeView()
                }
            }

            Text(activity.title)
                .font(AppFonts.Headline.bold(20))
                .foregroundStyle(AppColors.onBackground)

            HStack(spacing: 10) {
                MetricTileView(
                    label: "TOTAL VOLUME",
                    value: activity.totalVolume,
                    unit: "lbs"
                )

                MetricTileView(
                    label: "DURATION",
                    value: FeedFormatters.duration(activity.duration),
                    unit: ""
                )
            }

            HStack(spacing: 20) {
                FeedActionView(systemName: "heart.fill", count: activity.likes)
                FeedActionView(systemName: "bubble", count: activity.comments)

                Spacer()

                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppColors.onSurfaceVariant)
            }
            .padding(.top, 10)
        }
        .padding(16)
        .background(AppColors.surfaceVariant.opacity(0.74))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct MetricTileView: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(AppFonts.Body.bold(8))
                .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.72))

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(AppFonts.Headline.bold(25))
                    .foregroundStyle(AppColors.onBackground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)

                if !unit.isEmpty {
                    Text(unit)
                        .font(AppFonts.Body.bold(10))
                        .foregroundStyle(AppColors.onSurfaceVariant)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .topLeading)
        .background(Color.black.opacity(0.34))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

private enum FeedFormatters {
    static func duration(_ value: String) -> String {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let minutes = Int(trimmedValue) else {
            return trimmedValue
        }

        return DurationFormatters.workoutDuration(minutes: minutes)
    }
}

private struct PRBadgeView: View {
    var body: some View {
        HStack(spacing: 3) {
            Text("🔥")
                .font(.system(size: 10))

            Text("PR")
                .font(AppFonts.Body.bold(8))
        }
        .foregroundStyle(AppColors.onBackground)
        .frame(width: 43, height: 18)
        .background(Color.black.opacity(0.38))
        .clipShape(Capsule())
        .shadow(color: AppColors.primary.opacity(0.24), radius: 12, x: 0, y: 0)
    }
}

private struct FeedActionView: View {
    let systemName: String
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))

            Text("\(count)")
                .font(AppFonts.Body.bold(10))
        }
        .foregroundStyle(AppColors.onSurfaceVariant)
    }
}

private struct FollowPeopleEmptyView: View {
    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColors.surfaceBright.opacity(0.64))
                    .frame(width: 58, height: 58)

                Image(systemName: "person.2.badge.plus")
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(AppColors.onSurfaceVariant)
            }

            VStack(spacing: 8) {
                Text("Follow people to see activity")
                    .font(AppFonts.Body.bold(15))
                    .foregroundStyle(AppColors.onBackground)

                Text("Connect with fellow athletes to track\nprogress and share gains.")
                    .font(AppFonts.Body.medium(11))
                    .foregroundStyle(AppColors.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            Button {} label: {
                HStack(spacing: 7) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12, weight: .bold))

                    Text("FIND FRIENDS")
                        .font(AppFonts.Body.bold(11))
                }
                .foregroundStyle(AppColors.primaryFixed.opacity(0.64))
                .frame(height: 34)
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 245)
        .padding(.horizontal, 16)
        .background(AppColors.surface.opacity(0.92))
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(AppColors.outlineVariant.opacity(0.34), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
        )
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}
