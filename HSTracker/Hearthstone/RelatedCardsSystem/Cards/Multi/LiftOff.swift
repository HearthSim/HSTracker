//
//  LiftOff.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/22/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class LiftOff: ICardWithRelatedCards, ICardWithHighlight {
    private let starshipPieces: [Card?] = [
        Cards.any(byId: CardIds.NonCollectible.Invalid.Starport_Viking),
        Cards.any(byId: CardIds.NonCollectible.Invalid.Starport_Liberator),
        Cards.any(byId: CardIds.NonCollectible.Invalid.Starport_Raven2),
        Cards.any(byId: CardIds.NonCollectible.Invalid.Starport_Banshee2),
        Cards.any(byId: CardIds.NonCollectible.Invalid.Starport_Medivac2)
    ]

    required init() {
        // Required initializer
    }

    func getCardId() -> String {
        return CardIds.Collectible.Invalid.LiftOff
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return starshipPieces
    }
    
    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.faction == .terran)
    }
}
