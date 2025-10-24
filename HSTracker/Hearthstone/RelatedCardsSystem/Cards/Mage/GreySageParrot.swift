//
//  GreySageParrot.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/24/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class GreySageParrot: ICardWithRelatedCards {
    func getCardId() -> String {
        return CardIds.Collectible.Mage.GreySageParrot
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        if let lastSpell = player.cardsPlayedThisMatch
            .compactMap({ CardUtils.getProcessedCardFromEntity($0, player) })
            .last(where: { $0.type == .spell && $0.cost >= 6 }) {
            return [lastSpell]
        }
        return []
    }

    required init() {}
}
