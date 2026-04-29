//
//  OnboardingView.swift
//  GymBud
//
//  Created by Basu Singh on 23/04/26.
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    let onGetStarted: () -> Void

    init(onGetStarted: @escaping () -> Void = {}) {
        self.onGetStarted = onGetStarted
    }

    var body: some View {
        GeometryReader { geo in
            let safeWidth = sanitizedDimension(geo.size.width)
            let safeHeight = sanitizedDimension(geo.size.height)
            let contentWidth = min(max(safeWidth - 48, 0), 340)

            ZStack {
                Color.black
                    .ignoresSafeArea()

                Image(viewModel.content.backgroundImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: safeWidth, height: safeHeight)
                    .clipped()
                    .ignoresSafeArea()

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.82),
                        Color.black.opacity(0.55),
                        Color.black.opacity(0.90)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 190)

                    VStack(spacing: 0) {
                        topBrandSection
                            .padding(.bottom, 34)

                        titleAndSubtitleSection(contentWidth: contentWidth)
                            .padding(.bottom, 34)

                        buttonsSection(contentWidth: contentWidth)
                            .padding(.bottom, 20)

                        footerSection
                    }
                    .frame(width: contentWidth)

                    Spacer(minLength: 0)
                }
                .frame(width: safeWidth, height: safeHeight, alignment: .top)
            }
        }
    }
}

private extension OnboardingView {
    var topBrandSection: some View {
        VStack(spacing: 10) {
            Text(viewModel.content.appName)
                .font(AppFonts.Headline.bold(34))
                .foregroundStyle(AppColors.onBackground)
                .multilineTextAlignment(.center)

            Text(viewModel.content.tagline.uppercased())
                .font(AppFonts.Body.bold(11))
                .foregroundStyle(AppColors.secondary)
                .tracking(3)
                .multilineTextAlignment(.center)
        }
    }

    func titleAndSubtitleSection(contentWidth: CGFloat) -> some View {
        VStack(spacing: 20) {
            HStack(spacing: 0) {
                Text(viewModel.content.titlePrefix + " ")
                    .foregroundStyle(AppColors.onBackground)

                Text(viewModel.content.titleHighlight)
                    .foregroundStyle(AppColors.primary)
            }
            .font(AppFonts.Headline.bold(30))
            .frame(width: contentWidth, alignment: .center)

            Text(viewModel.content.subtitle)
                .font(AppFonts.Body.medium(15))
                .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.82))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(width: min(contentWidth, 290))
        }
    }

    func buttonsSection(contentWidth: CGFloat) -> some View {
        VStack(spacing: 16) {
            GBPrimaryButton(title: viewModel.content.primaryButtonTitle) {
                viewModel.didTapGetStarted()
                onGetStarted()
            }

            GBSecondaryButton(title: viewModel.content.secondaryButtonTitle) {
                viewModel.didTapSignIn()
            }
        }
        .frame(width: contentWidth)
    }

    var footerSection: some View {
        Text(viewModel.content.footerVersion)
            .font(AppFonts.Body.medium(11))
            .foregroundStyle(AppColors.onSurfaceVariant.opacity(0.28))
    }

    func sanitizedDimension(_ value: CGFloat) -> CGFloat {
        guard value.isFinite else { return 0 }
        return max(value, 0)
    }
}

#Preview {
    OnboardingView()
}
