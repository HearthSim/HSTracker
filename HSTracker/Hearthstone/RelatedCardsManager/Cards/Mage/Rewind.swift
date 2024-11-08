//
//  Rewind.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/7/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class Rewind: ICardWithRelatedCards {
    
    func getCardId() -> String {
        return CardIds.Collectible.Mage.Rewind
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return player.spellsPlayedCards
            .compactMap { CardUtils.getProcessedCardFromCardId($0.cardId, player) }
            .unique()
            .filter { $0.id != CardIds.Collectible.Mage.Rewind }
            .sorted { $0.cost > $1.cost }
    }

    required init() {
    }
}
