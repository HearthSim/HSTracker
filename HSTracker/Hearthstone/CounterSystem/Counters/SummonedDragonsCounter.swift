//
//  SummonedDragonsCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/29/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class SummonedDragonsCounter: NumericCounter {
    override var localizedName: String {
        return String.localizedString("Counter_SummonedDragons", comment: "")
    }
    
    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Priest.TimewinderZarimi
    }
    
    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Priest.TimewinderZarimi,
            CardIds.Collectible.Druid.FyeTheSettingSun
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
        
        return counter >= 2 && opponentMayHaveRelevantCards()
    }
    
    override func getCardsToDisplay() -> [String] {
        return isPlayerCounter ? getCardsInDeckOrKnown(cardIds: relatedCards) : filterCardsByClassAndFormat(cardIds: relatedCards, playerClass: game.opponent.playerClass)
    }
    
    override func valueToShow() -> String {
        return String(counter)
    }
    
    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }
        
        if entity[.controller] != (isPlayerCounter ? game.player.id : game.opponent.id) {
            return
        }
        
        guard entity.isMinion, entity.card.isDragon() else { return }
        
        if tag != .zone || value != Zone.play.rawValue {
            return
        }
        
        counter += 1
    }
}
