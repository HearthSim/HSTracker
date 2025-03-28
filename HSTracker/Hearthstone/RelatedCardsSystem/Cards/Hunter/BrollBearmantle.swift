//
//  BrollBearmantle.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class BrollBearmantle: ICardWithHighlight, ICardWithRelatedCards {
    required init() {
        
    }
    
    private let animalCompanions: [Card?] = [
        Cards.any(byId: CardIds.NonCollectible.Hunter.Misha),
        Cards.any(byId: CardIds.NonCollectible.Hunter.Leokk),
        Cards.any(byId: CardIds.NonCollectible.Hunter.Huffer)
    ]
    
    func getCardId() -> String {
        return CardIds.Collectible.Hunter.BrollBearmantle
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.type == .spell)
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return animalCompanions
    }
}
