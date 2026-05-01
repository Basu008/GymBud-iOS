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
        static let loadingButtonTitle = "LOGGING IN"
        static let genericErrorMessage = "Unable to log in. Please check your credentials."
    }

    enum UserInfo {
        static let titlePrefix = "BEFORE WE"
        static let titleHighlight = "START..."
        static let fullName = "FULL NAME"
        static let fullNamePlaceholder = "ALEX RIVERA"
        static let dateOfBirth = "DATE OF BIRTH"
        static let genderIdentity = "GENDER IDENTITY"
        static let kineticMetrics = "KINETIC METRICS"
        static let height = "HEIGHT (CM)"
        static let weight = "WEIGHT"
        static let saveChanges = "SAVE CHANGES"
        static let savingChanges = "SAVING CHANGES"
        static let keyboardDone = "Done"
        static let missingTokenMessage = "Please log in again to update your profile."
        static let genericErrorMessage = "Unable to update profile. Please try again."
        static let requiredNameMessage = "Name is required."
        static let invalidHeightMessage = "Height must be between 54.6 cm and 272 cm"
        static let invalidWeightMessage = "Weight must be between 20 kg and 635 kg"
    }
}
