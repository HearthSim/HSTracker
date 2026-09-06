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
        // HDT polls this through every gameplay scene because its
        // board-entry-order overlay consumes the friendly zone in
        // Constructed. HSTracker has no such overlay, so the only consumer
        // is Battlegrounds' Tavern Pinning - and at a 16ms cadence on the
        // single serial mirror queue every other watcher shares, polling
        // through Constructed matches would be pure contention. Skip the
        // read instead of stopping the thread, so the watcher still picks up
        // the next Battlegrounds match without needing its own lifecycle.
        guard AppDelegate.instance().coreManager.game.isBattlegroundsMatch() else {
            if _prev != nil {
                _prev = nil
            }
            return false
        }

        // HDT passes Config.ShowBoardEntryOrder && IsTraditionalHearthstoneMatch
        // for the friendly zone; with no board-entry-order overlay here the
        // friendly half is never read and the mirror can skip it.
        let state = MirrorHelper.getBoardState(includeFriendly: false)
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
