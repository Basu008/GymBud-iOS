//
//  RoutineListChangeStore.swift
//  GymBud
//
//  Created by Codex on 11/05/26.
//

import Foundation

@MainActor
final class RoutineListChangeStore {
    static let shared = RoutineListChangeStore()

    private var deletedRoutineIDs: Set<String> = []

    private init() {}

    func recordDeletedRoutineID(_ id: String) {
        deletedRoutineIDs.insert(id)
    }

    func filteredRoutines(_ routines: [Routine]) -> [Routine] {
        guard !deletedRoutineIDs.isEmpty else { return routines }
        return routines.filter { !deletedRoutineIDs.contains($0.id) }
    }
}
