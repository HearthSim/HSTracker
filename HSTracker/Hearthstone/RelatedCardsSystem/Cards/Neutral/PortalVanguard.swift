//
//  PortalVanguard.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/16/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class PortalVanguard: ICardWithHighlight {
    func getCardId() -> String {
        return CardIds.Collectible.Neutral.PortalVanguard
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.type == .minion)
    }

    required init() {}
}
