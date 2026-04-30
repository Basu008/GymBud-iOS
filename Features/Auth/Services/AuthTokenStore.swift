//
//  AuthTokenStore.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import Foundation

nonisolated protocol AuthTokenStoreProtocol: Sendable {
    nonisolated var accessToken: String? { get }
    nonisolated func saveAccessToken(_ token: String)
}

nonisolated final class AuthTokenStore: AuthTokenStoreProtocol, @unchecked Sendable {
    private let userDefaults: UserDefaults
    private let accessTokenKey = "auth.accessToken"

    nonisolated init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    nonisolated var accessToken: String? {
        userDefaults.string(forKey: accessTokenKey)
    }

    nonisolated func saveAccessToken(_ token: String) {
        userDefaults.set(token, forKey: accessTokenKey)
    }
}
