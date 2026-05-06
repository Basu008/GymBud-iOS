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
    @Published private(set) var isLoadingMore = false
    @Published private(set) var deletingRoutineIDs: Set<String> = []
    @Published var errorMessage: String?

    private let routineService: any RoutineServiceProtocol
    private var currentPage = 1
    private var canLoadMorePages = true

    init() {
        self.routineService = RoutineService()
    }

    init(initialRoutines: [Routine], initialErrorMessage: String?) {
        self.routineService = RoutineService()
        self.routines = initialRoutines
        self.errorMessage = initialErrorMessage
        self.canLoadMorePages = !initialRoutines.isEmpty
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
        currentPage = 1
        canLoadMorePages = true

        defer {
            isLoading = false
        }

        do {
            routines = try await routineService.routines(page: currentPage, accessToken: accessToken)
            canLoadMorePages = !routines.isEmpty
        } catch {
            routines = []
            errorMessage = "Unable to load routines."
        }
    }

    func loadMoreRoutinesIfNeeded(currentRoutine: Routine) async {
        guard currentRoutine.id == routines.last?.id,
              canLoadMorePages,
              !isLoading,
              !isLoadingMore
        else {
            return
        }

        guard let accessToken = routineService.storedAccessToken(),
              !accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return
        }

        isLoadingMore = true
        defer {
            isLoadingMore = false
        }

        do {
            let nextPage = currentPage + 1
            let nextRoutines = try await routineService.routines(page: nextPage, accessToken: accessToken)
            canLoadMorePages = !nextRoutines.isEmpty
            currentPage = nextPage
            appendRoutines(nextRoutines)
        } catch {
            canLoadMorePages = false
        }
    }

    func deleteRoutine(_ routine: Routine) async {
        guard !deletingRoutineIDs.contains(routine.id) else { return }

        guard let accessToken = routineService.storedAccessToken(),
              !accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            errorMessage = "Please log in again to delete routines."
            return
        }

        deletingRoutineIDs.insert(routine.id)
        errorMessage = nil

        defer {
            deletingRoutineIDs.remove(routine.id)
        }

        do {
            let deletedID = try await routineService.deleteRoutine(id: routine.id, accessToken: accessToken)
            routines.removeAll { $0.id == deletedID }
        } catch {
            errorMessage = "Unable to delete routine."
        }
    }

    private func appendRoutines(_ nextRoutines: [Routine]) {
        let existingIDs = Set(routines.map(\.id))
        routines.append(contentsOf: nextRoutines.filter { !existingIDs.contains($0.id) })
    }
}
