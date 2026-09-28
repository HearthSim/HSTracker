//
//  PlayZoneWatcher.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/21/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// Mirrors HDT's HearthWatcher/PlayZoneWatcher + EventArgs/BoardStateArgs.
//
// Polls ZoneMgr's play zones for the cards on each side of the board, plus
// which slot the cursor is over. In Battlegrounds the *opposing* play zone is
// Bob's shop, which is what the Tavern Pinning markers are drawn against.
struct PlayZoneArgs: Equatable {
    let boardCards: [MirrorBoardCard]
    let mousedOverSlot: Int

    // HDT compares by entity id, zone position and hover only - the card ids
    // ride along on the same entities, and comparing the whole card would make
    // every poll a deep compare.
    static func == (lhs: PlayZoneArgs, rhs: PlayZoneArgs) -> Bool {
        if lhs.mousedOverSlot != rhs.mousedOverSlot {
            return false
        }
        if lhs.boardCards.count != rhs.boardCards.count {
            return false
        }
        for (i, thisCard) in lhs.boardCards.enumerated() {
            let otherCard = rhs.boardCards[i]
            if thisCard.entityId != otherCard.entityId {
                return false
            }
            if thisCard.zonePosition != otherCard.zonePosition {
                return false
            }
            if thisCard.hovered != otherCard.hovered {
                return false
            }
        }
        return true
    }
}

struct BoardStateArgs: Equatable {
    let friendly: PlayZoneArgs?
    let opposing: PlayZoneArgs?
}

class PlayZoneWatcher: Watcher {
    var change: ((_ sender: PlayZoneWatcher, _ args: BoardStateArgs) -> Void)?
    private var _prev: BoardStateArgs?

    // HDT polls this one at 16ms - it drives a hover indicator, so it has to
    // keep up with the cursor rather than with game state.
    override init(delay: TimeInterval = 0.016) {
        super.init(delay: delay)
    }

    private static func toArgs(_ state: MirrorPlayZoneState?) -> PlayZoneArgs? {
        guard let state else { return nil }
        return PlayZoneArgs(boardCards: state.boardCards, mousedOverSlot: state.mousedOverSlot.intValue)
    }

    override func cleanup() {
        _prev = nil
    }

    override func update() -> Bool {
        // HDT polls this through every gameplay scene. Its two consumers are
        // Battlegrounds' Tavern Pinning and, in traditional Hearthstone, the
        // board entry order overlay; when neither is live - the setting is
        // off by default - a 16ms read on the single serial mirror queue
        // every other watcher shares would be pure contention. Skip the read
        // instead of stopping the thread, so the watcher still picks up the
        // next match without needing its own lifecycle.
        let game = AppDelegate.instance().coreManager.game
        // HDT's HearthMirrorBoardStateProvider.NeedsFriendlyZone.
        let needsFriendlyZone = Settings.showBoardEntryOrder && game.isTraditionalHearthstoneMatch
        guard needsFriendlyZone || game.isBattlegroundsMatch() else {
            if _prev != nil {
                _prev = nil
            }
            return false
        }

        let state = MirrorHelper.getBoardState(includeFriendly: needsFriendlyZone)
        let curr = BoardStateArgs(friendly: Self.toArgs(state?.friendly),
                                  opposing: Self.toArgs(state?.opposing))
        if curr == _prev {
            return false
        }
        change?(self, curr)
        _prev = curr
        return false
    }
}
