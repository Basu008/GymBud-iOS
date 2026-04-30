//
//  OnboardingContent.swift
//  GymBud
//
//  Created by Basu Singh on 23/04/26.
//

import Foundation

struct OnboardingContent {
    let appName: String
    let tagline: String
    let titlePrefix: String
    let titleHighlight: String
    let subtitle: String
    let primaryButtonTitle: String
    let secondaryButtonTitle: String
    let footerVersion: String

    static let mock = OnboardingContent(
        appName: AppStrings.Onboarding.appName,
        tagline: AppStrings.Onboarding.tagline,
        titlePrefix: AppStrings.Onboarding.titlePrefix,
        titleHighlight: AppStrings.Onboarding.titleHighlight,
        subtitle: AppStrings.Onboarding.subtitle,
        primaryButtonTitle: AppStrings.Onboarding.getStarted,
        secondaryButtonTitle: AppStrings.Onboarding.signIn,
        footerVersion: AppStrings.Onboarding.versionText
    )
}
