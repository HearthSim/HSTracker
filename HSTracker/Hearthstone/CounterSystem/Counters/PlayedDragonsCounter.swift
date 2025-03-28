//
//  PlayedDragonsCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class PlayedDragonsCounter: NumericCounter {
    override var localizedName: String {
        return String.localizedString("Counter_PlayedDragons", comment: "")
    }
    
    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Priest.TimewinderZarimi
    }
    
    override var relatedCards: [String] {
        return [ CardIds.Collectible.Priest.TimewinderZarimi ]
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
        if isPlayerCounter {
            return getCardsInDeckOrKnown(cardIds: relatedCards)
        } else {
            return filterCardsByClassAndFormat(cardIds: relatedCards, playerClass: game.opponent.originalClass)
        }
    }
    
    override func valueToShow() -> String {
        return "\(counter)"
    }
    
    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }
        
        if entity.isControlled(by: game.player.id) != isPlayerCounter {
            return
        }
        
        if !entity.isMinion {
            return
        }
        
        if !entity.card.isDragon() {
            return
        }
        
        if tag != .zone {
            return
        }
        
        if value != Zone.play.rawValue {
            return
        }
        
        if AppDelegate.instance().coreManager.logReaderManager.powerGameStateParser.currentBlock?.type != "PLAY" {
            return
        }
        
        counter += 1
    }
}
