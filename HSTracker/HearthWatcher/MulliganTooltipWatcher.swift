//
//  MulliganTooltipWatcher.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// Port of HDT's HearthWatcher/MulliganTooltipWatcher.cs.
//
// Tracks the tooltip Hearthstone draws beside a moused-over card during the
// Battlegrounds hero picking phase - the offered hero's hero power, and its
// buddy when buddies are on. The overlay covers that corner of the client, so
// the tooltip has to be cut out of it (see setHeroPickingTooltipMask).
struct MulliganTooltipArgs: Equatable {
    var zoneSize: Int
    var zonePosition: Int
    var isTooltipOnRight: Bool
    var tooltipCards: [String]

    init(state: MirrorMulliganTooltipState?) {
        zoneSize = state?.zoneSize.intValue ?? 0
        zonePosition = state?.zonePosition.intValue ?? 0
        isTooltipOnRight = state?.isTooltipOnRight ?? false
        tooltipCards = state?.tooltipCards.map { $0.cardId } ?? [String]()
    }
}

class MulliganTooltipWatcher: Watcher {
    var change: ((_ sender: MulliganTooltipWatcher, _ args: MulliganTooltipArgs) -> Void)?

    private var _prev: MulliganTooltipArgs?

    override init(delay: TimeInterval = 0.016) {
        super.init(delay: delay)
    }

    override func cleanup() {
        _prev = nil
    }

    override func update() -> Bool {
        let curr = MulliganTooltipArgs(state: MirrorHelper.getMulliganTooltipState())
        if curr == _prev {
            return false
        }
        change?(self, curr)
        _prev = curr
        return false
    }
}
