//
//  HomeStartupData.swift
//  GymBud
//
//  Created by Codex on 06/05/26.
//

import Foundation

struct HomeStartupData {
    var workoutRoutines: [Routine] = []
    var workoutErrorMessage: String?
    var routineRoutines: [Routine] = []
    var routineErrorMessage: String?
    var analytics: WorkoutAnalyticsPayload?
    var analyticsWorkouts: [WorkoutLog] = []
    var analyticsErrorMessage: String?
    var recentWorkouts: [WorkoutLog] = []
    var profileErrorMessage: String?
    var personalRecordPage: PersonalRecordsPayload?
    var personalRecordsErrorMessage: String?
}
