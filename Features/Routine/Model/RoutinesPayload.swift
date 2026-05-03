//
//  RoutinesPayload.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import Foundation

nonisolated struct RoutinesPayload: Decodable, Sendable {
    let routines: [Routine]
}
