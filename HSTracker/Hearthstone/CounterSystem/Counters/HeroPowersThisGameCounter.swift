//
//  HeroPowersThisGameCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class HeroPowersThisGameCounter: NumericCounter {
    override var cardIdToShowInUI: String? {
        CardIds.Collectible.Shaman.GlowrootLure
    }

    override var relatedCards: [String] {
        return [CardIds.Collectible.Shaman.GlowrootLure]
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        if !game.isTraditionalHearthstoneMatch { return false }
        if isPlayerCounter {
            return inPlayerDeckOrKnown(cardIds: relatedCards)
        }
        return counter > 1 && opponentMayHaveRelevantCards()
    }

    override func getCardsToDisplay() -> [String] {
        return isPlayerCounter ?
        getCardsInDeckOrKnown(cardIds: relatedCards) :
        filterCardsByClassAndFormat(cardIds: relatedCards, playerClass: game.opponent.originalClass)
    }

    override func valueToShow() -> String {
        return "\(counter)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }
        guard tag == .num_times_hero_power_used_this_game else { return }
        guard value > 0 else { return }

        let controller = entity[.controller]

        if (controller == game.player.id && isPlayerCounter) ||
           (controller == game.opponent.id && !isPlayerCounter) {
            counter = value
        }
    }
}
