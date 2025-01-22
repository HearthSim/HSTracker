//
//  ChattyMaccaw.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/21/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class ChattyMacaw: ICardWithRelatedCards {
    required init() {
        
    }

    func getCardId() -> String {
        return CardIds.Collectible.Hunter.ChattyMacaw
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        if let lastCard = player.spellsPlayedInOpponentCharacters.compactMap({ entity in CardUtils.getProcessedCardFromEntity(entity, player) }).last {
            return [ lastCard ]
        } else {
            return [Card?]()
        }
    }
}
