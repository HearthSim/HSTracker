//
//  FatigueCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/28/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class FatigueCounter: NumericCounter {
    
    override var localizedName: String {
        return String.localizedString("Counter_Fatigue", comment: "")
    }
    
    override var cardIdToShowInUI: String? {
        return CardIds.NonCollectible.Neutral.SkullOfGuldanSTORMWIND1
    }
    
    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Warlock.BaritoneImp,
            CardIds.Collectible.Warlock.Crescendo,
            CardIds.Collectible.Warlock.EncroachingInsanity,
            CardIds.Collectible.Warlock.CrazedConductor,
            CardIds.NonCollectible.Warlock.CurseofAgony_AgonyToken
        ]
    }
    
    /**
     * If these cards are in the *friendly* deck they should show the *opponent's* counter.
     */
    public var relatedCardsForOpponent = [
        CardIds.Collectible.Warlock.EncroachingInsanity,
        CardIds.Collectible.Warlock.CurseOfAgony
    ]

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        guard game.isTraditionalHearthstoneMatch else { return false }
        
        if isPlayerCounter {
            return counter > 0 || inPlayerDeckOrKnown(cardIds: relatedCards)
        }
        return counter > 0 || inPlayerDeckOrKnown(cardIds: relatedCardsForOpponent)
    }

    override func getCardsToDisplay() -> [String] {
        return isPlayerCounter ? getCardsInDeckOrKnown(cardIds: relatedCards) : getCardsInDeckOrKnown(cardIds: relatedCardsForOpponent) +  filterCardsByClassAndFormat(cardIds: relatedCards, playerClass: game.opponent.originalClass)
    }

    override func valueToShow() -> String {
        return "\(counter + 1)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }
        
        if tag == .fatigue, value != 0 {
            let controller = entity[.controller]
            if (controller == game.player.id && isPlayerCounter) || (controller == game.opponent.id && !isPlayerCounter) {
                counter = value
            }
        }
    }
}
