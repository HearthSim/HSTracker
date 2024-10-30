//
//  WheelOfDeathTurnsCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/29/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class WheelOfDeathTurnsCounter: NumericCounter {
    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Warlock.WheelOfDeath
    }

    override var relatedCards: [String] {
        return []
    }

    var isWheelOfDeathInPlay: Bool = false

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        return game.isTraditionalHearthstoneMatch && isWheelOfDeathInPlay
    }

    override func getCardsToDisplay() -> [String] {
        return [CardIds.Collectible.Warlock.WheelOfDeath]
    }

    override func valueToShow() -> String {
        return String(counter)
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }
        
        if tag == .zone,
           value == Zone.play.rawValue,
           entity.card.id == CardIds.Collectible.Warlock.WheelOfDeath,
           entity[.controller] == (isPlayerCounter ? game.player.id : game.opponent.id) {
            isWheelOfDeathInPlay = true
        }
        
        guard entity.card.id == CardIds.NonCollectible.Warlock.WheelofDEATH_WheelOfDeathCounterEnchantment else { return }
        
        if tag == .tag_script_data_num_1 {
            let controller = entity[.controller]
            
            if (controller == game.player.id && isPlayerCounter) || (controller == game.opponent.id && !isPlayerCounter) {
                counter = value
            }
        }
    }
}
