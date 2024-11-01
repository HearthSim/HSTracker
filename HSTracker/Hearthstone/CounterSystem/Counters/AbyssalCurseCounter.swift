//
//  AbyssalCurseCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/22/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class AbyssalCurseCounter: NumericCounter {
    
    override var cardIdToShowInUI: String? {
        return CardIds.NonCollectible.Warlock.SirakessCultist_AbyssalCurseToken
    }
    
    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Warlock.DraggedBelow,
            CardIds.Collectible.Warlock.SirakessCultist,
            CardIds.Collectible.Warlock.AbyssalWave,
            CardIds.Collectible.Warlock.Zaqul
        ]
    }
    
    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }
    
    override func shouldShow() -> Bool {
        if !game.isTraditionalHearthstoneMatch {
            return false
        }
        if isPlayerCounter {
            return counter > 0
        } else {
            return counter > 0
        }
    }
    
    override func getCardsToDisplay() -> [String] {
        if isPlayerCounter {
            return getCardsInDeckOrKnown(cardIds: relatedCards)
        } else {
            return [CardIds.NonCollectible.Warlock.SirakessCultist_AbyssalCurseToken]
        }
    }
    
    override func valueToShow() -> String {
        return String(counter)
    }
    
    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }
        
        if entity.card.id != CardIds.NonCollectible.Warlock.SirakessCultist_AbyssalCurseToken {
            return
        }
        
        if tag != .tag_script_data_num_1 {
            return
        }
        
        let controller = entity[.controller]
        if (controller == game.player.id && isPlayerCounter) || (controller == game.opponent.id && !isPlayerCounter) {
            counter = value
        }
    }
}
