//
//  FeedActivity.swift
//  GymBud
//
//  Created by Codex on 01/05/26.
//

import Foundation

struct FeedActivity: Identifiable {
    let id = UUID()
    let athleteName: String
    let timestamp: String
    let title: String
    let totalVolume: String
    let duration: String
    let likes: Int
    let comments: Int
    let isPR: Bool
}
