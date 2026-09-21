//
//  ArrivalOfTheOldGods.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/21/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Draw 2 minions. Refresh 5 Mana Crystals. You can only play minions for the rest of the turn."
class ArrivalOfTheOldGods: ICardWithHighlight {
    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.Deathknight.ArrivalOfTheOldGods
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(card.type == .minion)
    }
}
