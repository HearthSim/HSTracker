//
//  CounterCatalog.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/23/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

/// Everything the counters settings pane can configure: one descriptor per counter type.
///
/// There is no list of counters here. `ReflectionHelper` already finds every `BaseCounter`
/// subclass for `CounterManager`, and this reads from the same place, so adding a counter
/// needs nothing in this file.
enum CounterCatalog {
    private static let lock = NSLock()

    private static var _descriptors: [CounterDescriptor]?

    /// Persistence keys of every counter this build knows about. Independent of the probes,
    /// so it can be asked for without a game.
    static var knownCounterIds: Set<String> {
        return Set(ReflectionHelper.getCounterClasses().map { $0.counterId })
    }

    /// One descriptor per counter type. Built on first use only - from the settings pane,
    /// never from the startup path - because building it instantiates every counter.
    static func descriptors(game: Game) -> [CounterDescriptor] {
        lock.lock()
        defer { lock.unlock() }
        if let descriptors = _descriptors {
            return descriptors
        }
        // Ordering is deliberately not applied here: the display name is live, so a
        // card-language change would leave a cached order stale. The settings pane sorts
        // when it binds.
        let descriptors = ReflectionHelper.getCounterClasses().map { type in
            CounterDescriptor(probe: type.init(controlledByPlayer: true, game: game))
        }
        _descriptors = descriptors
        return descriptors
    }
}
