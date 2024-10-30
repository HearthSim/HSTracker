//
//  CtunCounter.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/28/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class CthunCounter: StatsCounter {
    
    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Neutral.Cthun
    }
    
    override var relatedCards: [String] {
        return [
            CardIds.Collectible.Neutral.Cthun
        ]
    }

    required init(controlledByPlayer: Bool, game: Game) {
        super.init(controlledByPlayer: controlledByPlayer, game: game)
    }

    override func shouldShow() -> Bool {
        guard game.isTraditionalHearthstoneMatch else { return false }
        
        if isPlayerCounter {
            return inPlayerDeckOrKnown(cardIds: relatedCards)
        } else {
            return (attackCounter > 2 || healthCounter > 2) && opponentMayHaveRelevantCards()
        }
    }

    override func getCardsToDisplay() -> [String] {
        return relatedCards
    }

    override func valueToShow() -> String {
        return "\(attackCounter + 6)/\(healthCounter + 6)"
    }

    override func handleTagChange(tag: GameTag, entity: Entity, value: Int, prevValue: Int) {
        guard game.isTraditionalHearthstoneMatch else { return }
        guard (tag == .cthun_attack_buff || tag == .cthun_health_buff) && value != 0 else { return }

        let controller = entity[.controller]

        if (controller == game.player.id && isPlayerCounter) || (controller == game.opponent.id && !isPlayerCounter) {
            if tag == .cthun_attack_buff {
                attackCounter = value
            } else if tag == .cthun_health_buff {
                healthCounter = value
            }
        }
    }
}
