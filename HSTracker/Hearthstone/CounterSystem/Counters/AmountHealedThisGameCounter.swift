//
//  AmountHealedThisGameCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/23/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// Crystal Stag: "Rush. Battlecry: If you've restored 5 Health this game, summon a copy of this."
class AmountHealedThisGameCounter: NumericCounter {
    override var localizedName: String {
        return String.localizedString("Counter_AmountHealedThisGame", comment: "")
    }

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Druid.CrystalStag
    }

    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Druid.CrystalStag
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

        if tag != .amount_healed_this_game {
            return
        }

        if value == 0 {
            return
        }

        let controller = entity[.controller]

        if controller == game.player.id && isPlayerCounter || controller == game.opponent.id && !isPlayerCounter {
            counter = value
        }
    }
}
