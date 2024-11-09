//
//  GalakrondCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/28/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class GalakrondCounter: NumericCounter {
    
    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Rogue.GalakrondTheNightmare
    }
    
    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Rogue.GalakrondTheNightmare,
            CardIds.Collectible.Shaman.GalakrondTheTempest,
            CardIds.Collectible.Warlock.GalakrondTheWretched,
            CardIds.Collectible.Priest.GalakrondTheUnspeakable,
            CardIds.Collectible.Warrior.GalakrondTheUnbreakable
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
        return counter > 0 && opponentMayHaveRelevantCards()
    }

    override func getCardsToDisplay() -> [String] {
        return isPlayerCounter ? getCardsInDeckOrKnown(cardIds: relatedCards) : filterCardsByClassAndFormat(cardIds: relatedCards, playerClass: game.opponent.originalClass)
    }

    override func valueToShow() -> String {
        return "\(counter)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }
        
        if tag == .invoke_counter, value != 0 {
            let controller = entity[.controller]
            if (controller == game.player.id && isPlayerCounter) || (controller == game.opponent.id && !isPlayerCounter) {
                counter = value
            }
        }
    }
}
