//
//  CounterVisibility.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/22/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

/// How one counter, or one card of the opponent's "Related Cards" list, is shown.
///
/// Shared by the counters and the related cards settings panes, as HDT's `CounterVisibility`
/// is. The raw values are HDT's, so a config carried over either way reads the same.
enum CounterVisibility: Int, CaseIterable {
    /// The counter's (or card's) own heuristic decides.
    case auto = 0
    /// Never shown, whatever the heuristic says.
    case disabled = 1
    /// Always shown, even when the heuristic would hide it.
    case enabled = 2
}
