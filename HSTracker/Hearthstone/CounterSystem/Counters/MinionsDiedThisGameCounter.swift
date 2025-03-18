//
//  MinionsDiedThisGameCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/18/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class MinionsDiedThisGameCounter: NumericCounter {

    override var cardIdToShowInUI: String? {
        CardIds.Collectible.Deathknight.ReskaThePitBoss
    }

    override var relatedCards: [String] {
        [
            CardIds.Collectible.Deathknight.ReskaThePitBoss
        ]
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        guard game.isTraditionalHearthstoneMatch else { return false }
        if isPlayerCounter {
            return inPlayerDeckOrKnown(cardIds: relatedCards)
        }
        return !inPlayerDeckOrKnown(cardIds: relatedCards) && opponentMayHaveRelevantCards()
    }

    override func getCardsToDisplay() -> [String] {
        if isPlayerCounter {
            return getCardsInDeckOrKnown(cardIds: relatedCards)
        } else {
            return filterCardsByClassAndFormat(cardIds: relatedCards, playerClass: game.opponent.originalClass)
        }
    }

    override func valueToShow() -> String {
        String(counter)
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }
        guard game.isMulliganDone() else { return }
        guard entity.isMinion else { return }
        guard tag == .zone else { return }
        guard prevValue == Zone.play.rawValue else { return }
        guard value == Zone.graveyard.rawValue else { return }

        counter += 1
    }
}
