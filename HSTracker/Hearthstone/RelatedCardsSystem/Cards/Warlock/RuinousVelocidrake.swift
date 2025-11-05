//
//  RuinousVelocidrake.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/4/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class RuinousVelocidrake: ICardWithHighlight {
    func getCardId() -> String {
        CardIds.Collectible.Warlock.RuinousVelocidrake
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(card.id == CardIds.NonCollectible.Warlock.TwilightTimehopper_ShredOfTimeToken)
    }

    required init() {}
}
