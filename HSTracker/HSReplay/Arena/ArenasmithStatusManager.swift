//
//  ArenasmithStatusManager.swift
//  HSTracker
//
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

struct ArenasmithAvailabilities: Equatable {
    let arena: Bool
    let undergroundArena: Bool

    static let none = ArenasmithAvailabilities(arena: false, undergroundArena: false)

    func isAvailable(isUnderground: Bool) -> Bool {
        isUnderground ? undergroundArena : arena
    }
}

/// Whether HSReplay is currently serving Arenasmith for each arena mode.
///
/// Two gates, both mirroring HDT: a remote-config kill switch that turns the whole
/// feature off, and a per-game-mode server flag. The result is cached for the
/// session, because HDT queries it once per draft rather than per pick.
@available(macOS 10.15, *)
final class ArenasmithStatusManager {
    static let instance = ArenasmithStatusManager()

    private var availabilities: ArenasmithAvailabilities?
    private let lock = UnfairLock()

    // The status response keys on the C# enum *name*, not its numeric value, and
    // HSTracker's BnetGameType is a plain Int enum with no name table.
    private static let arenaKey = "BGT_ARENA"
    private static let undergroundArenaKey = "BGT_UNDERGROUND_ARENA"

    private init() {}

    var cached: ArenasmithAvailabilities? {
        lock.around { availabilities }
    }

    func ensureAvailabilities() async -> ArenasmithAvailabilities {
        if RemoteConfig.data?.arenasmith?.disabled ?? false {
            let disabled = ArenasmithAvailabilities.none
            lock.around { availabilities = disabled }
            return disabled
        }

        if let cached = lock.around({ availabilities }) {
            return cached
        }

        guard let status = await HSReplayAPI.getArenasmithStatus(), let data = status.data else {
            // Deliberately not cached: a failed request should be retried on the next
            // draft rather than turning the feature off for the session.
            return .none
        }

        let result = ArenasmithAvailabilities(
            arena: data[Self.arenaKey]?.arenasmith ?? false,
            undergroundArena: data[Self.undergroundArenaKey]?.arenasmith ?? false
        )
        lock.around { availabilities = result }
        return result
    }

    func clear() {
        lock.around { availabilities = nil }
    }
}
