//
//  ArenaClientStateType.swift
//  HSTracker
//
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

/// Mirrors HearthMirror's `ArenaClientStateType`. The mirror hands this across the
/// ObjC boundary as a raw NSNumber, so the case order here - not the four-case
/// placeholder enum currently declared in the framework's Mirror.hpp - is what
/// actually has to match the game.
enum ArenaClientStateType: Int, CaseIterable {
    case none = 0,
         normalLanding,
         normalDraft,
         normalRedraft,
         normalReady,
         normalDeckEdit,
         normalDeckCollection,
         normalRewards,
         undergroundLanding,
         undergroundDraft,
         undergroundRedraft,
         undergroundReady,
         undergroundDeckEdit,
         undergroundDeckCollection,
         undergroundRewards

    /// Landing screen for either mode - where the pre-draft lobby is shown and where
    /// the trial status is still worth caching.
    var isLanding: Bool {
        self == .normalLanding || self == .undergroundLanding
    }

    /// Drafting or redrafting in either mode. Note this is *not* a reliable test for
    /// "is a redraft" on its own: the game sometimes reports `undergroundDraft` while
    /// redrafting, which is why the pick helper keys redraft off the session state.
    var isDrafting: Bool {
        switch self {
        case .normalDraft, .undergroundDraft, .normalRedraft, .undergroundRedraft:
            return true
        default:
            return false
        }
    }

    var isDeckEdit: Bool {
        self == .normalDeckEdit || self == .undergroundDeckEdit
    }
}
