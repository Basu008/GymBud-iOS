//
//  AppDataRefreshCenter.swift
//  GymBud
//
//  Created by Codex on 11/05/26.
//

import Foundation

extension Notification.Name {
    static let appDataDidChange = Notification.Name("appDataDidChange")
}

enum AppDataRefreshReason: String {
    case routineCreated
    case routineUpdated
    case routineDeleted
    case workoutCompleted
    case workoutDeleted
    case profileUpdated
}

enum AppDataRefreshCenter {
    @MainActor
    static func notifyChange(_ reason: AppDataRefreshReason, userInfo: [String: Any] = [:]) {
        var payload = userInfo
        payload["reason"] = reason.rawValue

        NotificationCenter.default.post(
            name: .appDataDidChange,
            object: nil,
            userInfo: payload
        )
    }
}
