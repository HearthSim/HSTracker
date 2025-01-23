//
//  ColossusCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/22/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class ColossusCounter: NumericCounter {
    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Mage.Colossus
    }

    override var relatedCards: [String] {
        return [CardIds.Collectible.Mage.Colossus]
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        guard game.isTraditionalHearthstoneMatch else { return false }
        if isPlayerCounter {
            return inPlayerDeckOrKnown(cardIds: relatedCards)
        }
        return counter > 2 && opponentMayHaveRelevantCards()
    }

    override func getCardsToDisplay() -> [String] {
        if isPlayerCounter {
            return getCardsInDeckOrKnown(cardIds: relatedCards)
        }
        return filterCardsByClassAndFormat(cardIds: relatedCards, playerClass: game.opponent.originalClass)
    }

    override func valueToShow() -> String {
        return String(format: String.localizedString("Counter_AsteroidDamage_Damage", comment: ""), "2x \(counter + 1)")
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }
        guard tag == .zone, (value == Zone.play.rawValue || value == Zone.secret.rawValue), entity.isSpell, entity.has(tag: .protoss) else { return }

        let controller = entity[.controller]
        if (controller == game.player.id && isPlayerCounter) || (controller == game.opponent.id && !isPlayerCounter) {
            counter += 1
        }
    }
}
