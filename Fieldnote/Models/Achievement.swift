//
//  Achievement.swift
//  Fieldnote
//
//  Persisted unlock record for a badge (Wave 2). Badge *definitions* are static
//  (see BadgeCatalog); these rows only track unlock state, mirroring how
//  CatalogPlant definitions are static while user Plants are persisted.
//  All stored properties are defaulted for CloudKit (.automatic) compatibility.
//

import Foundation
import SwiftData

@Model
final class Achievement {
    var identifier: String = ""
    var unlockedAt: Date?
    var seen: Bool = false

    init(identifier: String = "", unlockedAt: Date? = nil) {
        self.identifier = identifier
        self.unlockedAt = unlockedAt
    }
}
