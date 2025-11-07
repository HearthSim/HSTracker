//
//  GaronaHalforcenTheKingslayers.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/4/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class GaronaHalforcenTheKingslayers: ICardWithHighlight {
    func getCardId() -> String {
        CardIds.NonCollectible.Rogue.GaronaHalforcen_TheKingslayersToken
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(card.rarity == .legendary || (card.rarity == .invalid && card.mechanics.contains("ELITE")))
    }

    required init() {}
}
