//
//  FieldProfile.swift
//  Fieldnote
//
//  Persisted gamification profile (Wave 2). A single row, reconciled from
//  encounter history so it's always recoverable after a CloudKit sync loss.
//  All stored properties are defaulted for CloudKit (.automatic) compatibility.
//

import Foundation
import SwiftData

@Model
final class FieldProfile {
    var totalXP: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastObservationDate: Date?
    var createdAt: Date = Date.now

    init() {}

    // MARK: - Derived

    var level: Int { GamificationMath.level(forXP: totalXP) }

    var xpIntoLevel: Int { totalXP - GamificationMath.xpThreshold(forLevel: level) }

    var xpForNextLevel: Int {
        GamificationMath.xpThreshold(forLevel: level + 1) - GamificationMath.xpThreshold(forLevel: level)
    }

    var levelProgress: Double {
        xpForNextLevel > 0 ? min(1, Double(xpIntoLevel) / Double(xpForNextLevel)) : 0
    }
}

/// Level curve: cumulative XP to reach level L is `50 · (L-1) · L`.
/// L1 = 0, L2 = 100, L3 = 300, L4 = 600, L5 = 1000 …
enum GamificationMath {
    static func xpThreshold(forLevel level: Int) -> Int {
        guard level > 1 else { return 0 }
        return 50 * (level - 1) * level
    }

    static func level(forXP xp: Int) -> Int {
        var level = 1
        while xpThreshold(forLevel: level + 1) <= xp { level += 1 }
        return level
    }
}
