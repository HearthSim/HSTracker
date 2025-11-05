//
//  GladiatorialCombat.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/4/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class GladiatorialCombat: ICardWithHighlight, ICardWithRelatedCards {
    func getCardId() -> String {
        CardIds.Collectible.Warrior.GladiatorialCombat
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(card.type == .minion)
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        [Cards.by(cardId: CardIds.NonCollectible.Warrior.GladiatorialCombat_ColiseumTigerToken)]
    }

    required init() {}
}
