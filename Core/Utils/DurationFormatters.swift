//
//  DurationFormatters.swift
//  GymBud
//
//  Created by Codex on 04/05/26.
//

import Foundation

enum DurationFormatters {
    enum UnitStyle {
        case compact
        case abbreviated
    }

    static func workoutDuration(seconds: Int, unitStyle: UnitStyle = .abbreviated) -> String {
        workoutDuration(minutes: seconds / 60, unitStyle: unitStyle)
    }

    static func workoutDuration(minutes: Int, unitStyle: UnitStyle = .abbreviated) -> String {
        let totalMinutes = max(minutes, 1)

        guard totalMinutes > 59 else {
            switch unitStyle {
            case .compact:
                return "\(totalMinutes)m"
            case .abbreviated:
                return "\(totalMinutes) min"
            }
        }

        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        switch unitStyle {
        case .compact:
            return minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)m"
        case .abbreviated:
            return minutes == 0 ? "\(hours) hr" : "\(hours) hr \(minutes) min"
        }
    }
}

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
