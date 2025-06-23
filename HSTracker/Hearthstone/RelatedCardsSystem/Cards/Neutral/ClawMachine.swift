//
//  ClawMachine.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/23/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class ClawMachine: ICardWithHighlight {
    required init() {}

    func getCardId() -> String {
        CardIds.Collectible.Neutral.ClawMachine
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(card.type == .minion)
    }
}
