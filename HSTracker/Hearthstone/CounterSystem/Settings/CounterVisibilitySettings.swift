//
//  CounterVisibilitySettings.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/23/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

/// Reads and writes the per-counter, per-side visibility overrides.
///
/// Lookups have to be O(1): every counter value change re-runs `getVisibleCounters`, which
/// resolves the override for every counter instance. The stored overrides are therefore
/// projected into a dictionary that is reloaded only when something actually changes.
///
/// Storage is sparse: an entry only exists while at least one side is non-Auto, and a side
/// only has a value while it is non-Auto. A counter with no entry resolves to Auto for both
/// sides, which is what lets a newly added counter work without any config migration. HDT
/// keeps a list of `CounterVisibilityOverride` records in its XML config; HSTracker stores
/// the same thing as a counter id to `{player, opponent}` map in the user defaults.
///
/// Writing goes through `Settings.counterVisibilityOverrides`, whose change notification is
/// what refreshes the counters overlay - HDT's `Changed` event.
final class CounterVisibilitySettings {
    static let instance = CounterVisibilitySettings()

    static let playerKey = "player"
    static let opponentKey = "opponent"

    private init() {
    }

    private struct Entry {
        var player: CounterVisibility = .auto
        var opponent: CounterVisibility = .auto

        func get(_ isPlayer: Bool) -> CounterVisibility { isPlayer ? player : opponent }

        var isEmpty: Bool { player == .auto && opponent == .auto }
    }

    private var _lookup: [String: Entry]?

    private var lookup: [String: Entry] {
        if let lookup = _lookup {
            return lookup
        }
        var lookup = [String: Entry]()
        for (counterId, sides) in Settings.counterVisibilityOverrides where !counterId.isEmpty {
            var entry = Entry()
            entry.player = sides[Self.playerKey].flatMap(CounterVisibility.init(rawValue:)) ?? .auto
            entry.opponent = sides[Self.opponentKey].flatMap(CounterVisibility.init(rawValue:)) ?? .auto
            if !entry.isEmpty {
                lookup[counterId] = entry
            }
        }
        _lookup = lookup
        return lookup
    }

    func invalidate() {
        _lookup = nil
    }

    func get(_ counterId: String, isPlayer: Bool) -> CounterVisibility {
        return lookup[counterId]?.get(isPlayer) ?? .auto
    }

    func set(_ counterId: String, isPlayer: Bool, _ value: CounterVisibility) {
        if counterId.isEmpty || get(counterId, isPlayer: isPlayer) == value {
            return
        }

        var overrides = Settings.counterVisibilityOverrides
        var sides = overrides[counterId] ?? [:]
        let key = isPlayer ? Self.playerKey : Self.opponentKey
        if value == .auto {
            sides.removeValue(forKey: key)
        } else {
            sides[key] = value.rawValue
        }

        // Drop the whole entry once neither side is customised any more, including a
        // leftover Auto value from a hand-edited or older config.
        if sides.values.allSatisfy({ $0 == CounterVisibility.auto.rawValue }) {
            overrides.removeValue(forKey: counterId)
        } else {
            overrides[counterId] = sides
        }

        Settings.counterVisibilityOverrides = overrides
        invalidate()
    }

    /// Final decision for one counter: the user's override wins, otherwise the counter's own
    /// heuristic. The game-mode gate is deliberately not part of this - it is applied first
    /// (see `BaseCounter.isVisible`), so a forced counter still never shows in a mode it does
    /// not belong to.
    static func resolve(_ mode: CounterVisibility, _ heuristic: () -> Bool) -> Bool {
        switch mode {
        case .disabled:
            return false
        case .enabled:
            return true
        case .auto:
            return heuristic()
        }
    }

    var hasAnyOverride: Bool { !lookup.isEmpty }

    /// Clears every counter this build knows about. Entries for counters it does not know,
    /// e.g. written by a newer version, are left alone.
    func resetAll() {
        let known = CounterCatalog.knownCounterIds
        let overrides = Settings.counterVisibilityOverrides
        let kept = overrides.filter { !$0.key.isEmpty && !known.contains($0.key) }
        if kept.count == overrides.count {
            return
        }

        Settings.counterVisibilityOverrides = kept
        invalidate()
    }
}
