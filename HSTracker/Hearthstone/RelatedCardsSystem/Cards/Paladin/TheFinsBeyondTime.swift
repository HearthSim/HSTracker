//
//  TheFinsBeyondTime.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/4/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class TheFinsBeyondTime: ICardWithRelatedCards {
    func getCardId() -> String {
        CardIds.Collectible.Paladin.TheFinsBeyondTime
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        player.startingHand.map { entity in
            CardUtils.getProcessedCardFromEntity(entity, player)
        }
    }

    required init() {}
}
