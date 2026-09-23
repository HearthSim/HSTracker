//
//  BeastsSummonedThisGameCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/23/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// Knight of the Wild / Frostsaber Matriarch: "Costs (1) less for each Beast you've summoned this game."
class BeastsSummonedThisGameCounter: NumericCounter {
    override var localizedName: String {
        return String.localizedString("Counter_SummonedBeasts", comment: "")
    }

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Druid.KnightOfTheWild
    }

    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Druid.KnightOfTheWild,
            CardIds.Collectible.Druid.KnightOfTheWildWONDERS,
            CardIds.Collectible.Druid.FrostsaberMatriarch
        ]
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        guard game.isTraditionalHearthstoneMatch else { return false }

        return isPlayerCounter && inPlayerDeckOrKnown(cardIds: relatedCards)
    }

    override func getCardsToDisplay() -> [String] {
        return isPlayerCounter
            ? getCardsInDeckOrKnown(cardIds: relatedCards)
            : filterCardsByClassAndFormat(cardIds: relatedCards, playerClass: game.opponent.originalClass)
    }

    override func valueToShow() -> String {
        return String(counter)
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }

        if entity.isControlled(by: game.player.id) != isPlayerCounter {
            return
        }

        if !entity.isMinion {
            return
        }

        if !entity.latestCard.isBeast() {
            return
        }

        if tag != .zone {
            return
        }

        if value != Zone.play.rawValue {
            return
        }

        counter += 1
    }
}
