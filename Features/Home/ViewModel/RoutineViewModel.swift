//
//  RoutineViewModel.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import Combine
import Foundation

@MainActor
final class RoutineViewModel: ObservableObject {
    @Published private(set) var routines: [Routine] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let routineService: any RoutineServiceProtocol

    init() {
        self.routineService = RoutineService()
    }

    init(routineService: any RoutineServiceProtocol) {
        self.routineService = routineService
    }

    func loadRoutines() async {
        guard !isLoading else { return }

        guard let accessToken = routineService.storedAccessToken(),
              !accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            errorMessage = "Please log in again to view routines."
            routines = []
            return
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            routines = try await routineService.routines(accessToken: accessToken)
        } catch {
            routines = []
            errorMessage = "Unable to load routines."
        }
    }
}
