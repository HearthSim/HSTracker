//
//  SliceAndDice.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/30/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class SliceAndDice: ICardWithRelatedCards {

    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Rogue.SliceAndDice
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return player.cardsPlayedThisTurn
            .map { CardUtils.getProcessedCardFromEntity($0, player) }
            .filter { $0 != nil }
            .sorted { ($0?.cost ?? 0) > ($1?.cost ?? 0) }
    }
}
