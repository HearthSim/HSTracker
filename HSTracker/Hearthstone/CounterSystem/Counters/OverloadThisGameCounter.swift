//
//  OverloadThisGameCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class OverloadThisGameCounter: NumericCounter {

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Shaman.HaywireHornswog
    }

    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Shaman.HaywireHornswog
        ]
    }

    override func shouldShow() -> Bool {
        if !game.isTraditionalHearthstoneMatch {
            return false
        }
        return isPlayerCounter && inPlayerDeckOrKnown(cardIds: relatedCards)
    }

    override func getCardsToDisplay() -> [String] {
        return getCardsInDeckOrKnown(cardIds: relatedCards)
    }

    override func valueToShow() -> String {
        return "\(counter)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        if !game.isTraditionalHearthstoneMatch {
            return
        }

        if tag != .overload_this_game {
            return
        }

        if value == 0 {
            return
        }

        let controller = entity[.controller]

        if (controller == game.player.id && isPlayerCounter) || (controller == game.opponent.id && !isPlayerCounter) {
            counter = value
        }
    }
}
