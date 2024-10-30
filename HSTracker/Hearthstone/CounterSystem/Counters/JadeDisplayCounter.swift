//
//  JadeDisplayCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/29/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class JadeDisplayCounter: NumericCounter {
    
    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Druid.JadeDisplay
    }
    
    override var relatedCards: [String] {
        return [CardIds.Collectible.Druid.JadeDisplay]
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        guard game.isTraditionalHearthstoneMatch else { return false }
        
        if isPlayerCounter {
            return counter > 0 || inPlayerDeckOrKnown(cardIds: relatedCards)
        }
        return counter > 0 && opponentMayHaveRelevantCards()
    }

    override func getCardsToDisplay() -> [String] {
        return relatedCards
    }

    override func valueToShow() -> String {
        let jadeSize = counter + 1
        return "\(jadeSize)/\(jadeSize)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }

        if entity.card.id != CardIds.NonCollectible.Druid.JadeDisplay_JadeSalesEnchantment {
            return
        }

        if tag == .zone && value == Zone.play.rawValue {
            let controller = entity[.controller]
            if (controller == game.player.id && isPlayerCounter) || (controller == game.opponent.id && !isPlayerCounter) {
                counter += 1
            }
        }
    }
}
