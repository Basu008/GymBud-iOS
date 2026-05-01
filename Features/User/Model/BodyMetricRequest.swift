//
//  BodyMetricRequest.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import Foundation

nonisolated struct BodyMetricRequest: Encodable, Sendable {
    let heightCM: Double
    let weightKG: Double

    enum CodingKeys: String, CodingKey {
        case heightCM = "height_cm"
        case weightKG = "weight_kg"
    }
}
