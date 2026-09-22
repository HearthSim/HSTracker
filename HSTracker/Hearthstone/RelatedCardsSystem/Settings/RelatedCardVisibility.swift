//
//  RelatedCardVisibility.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/22/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

/// How one card is treated by the opponent's "Related Cards" list.
///
/// HDT shares its `CounterVisibility` enum between the counters options page and this
/// one; HSTracker has no counters options page, so the same three modes live here under
/// their own name. The raw values are HDT's, so a config carried over either way reads
/// the same.
enum RelatedCardVisibility: Int, CaseIterable {
    /// The card's own `shouldShowForOpponent` heuristic decides.
    case auto = 0
    /// Never listed, whatever the heuristic says.
    case disabled = 1
    /// Always listed, even if the opponent has not played the card yet.
    case enabled = 2
}
