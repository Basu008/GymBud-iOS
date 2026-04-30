//
//  AppStrings.swift
//  GymBud
//
//  Created by Basu Singh on 23/04/26.
//

import Foundation

enum AppStrings{
    enum Onboarding{
        static let appName = "GymBud"
        static let tagline = "A GYM PROGRESS TRACKER"
        static let titlePrefix = "UNLOCK YOUR"
        static let titleHighlight = "PR"
        static let subtitle = "Don't miss out gains just 'cause you are not able to track it."
        static let getStarted = "GET STARTED"
        static let signIn = "LOG IN"
        static let versionText = "v1.0.0"
    }

    enum SignUp {
        static let title = "CREATE\nACCOUNT"
        static let subtitle = "Join the movement and track your progress."
        static let username = "USERNAME"
        static let email = "EMAIL ADDRESS"
        static let password = "CREATE PASSWORD"
        static let confirmPassword = "CONFIRM PASSWORD"
        static let createAccount = "CREATE ACCOUNT"
        static let creatingAccount = "CREATING ACCOUNT"
        static let accountCreated = "ACCOUNT CREATED"
        static let existingAccount = "Already have an account?"
        static let signIn = "LOG IN"
        static let successMessage = "Account created successfully."
        static let genericErrorMessage = "Unable to create account. Please try again."
    }

    enum LogIn {
        static let title = "LOG IN"
        static let subtitle = "Access your training matrix."
        static let username = "USERNAME"
        static let password = "PASSWORD"
        static let usernamePlaceholder = "Enter your username"
        static let passwordPlaceholder = "***********"
        static let primaryButtonTitle = "LOG IN"
        static let footerPrefix = "New to the app?"
        static let footerActionTitle = "CREATE ACCOUNT"
        static let invalidUsernameMessage = "username is invalid"
        static let invalidPasswordMessage = "incorrect password"
    }
}
