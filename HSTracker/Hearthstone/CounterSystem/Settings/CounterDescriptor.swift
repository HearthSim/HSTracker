//
//  CounterDescriptor.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/23/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

/// UI metadata for one counter type, used by the counters settings pane.
///
/// Backed by a throwaway "probe" instance rather than static metadata, because a counter's
/// portrait and name are instance properties (ImbueCounter's portrait even depends on game
/// state). Reading through to the probe also means a card-language change is picked up
/// without rebuilding anything.
final class CounterDescriptor {
    private let probe: BaseCounter

    init(probe: BaseCounter) {
        self.probe = probe
        counterId = probe.counterId
        isBattlegroundsCounter = probe.isBattlegroundsCounter
    }

    let counterId: String

    let isBattlegroundsCounter: Bool

    var displayName: String { probe.localizedName }

    var usesFallbackDisplayName: Bool { probe.usesFallbackDisplayName }

    var cardIdToShowInUI: String? { probe.cardIdToShowInUI }
}
