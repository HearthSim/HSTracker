//
//  DomainOfYoggSaron.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// Mastermind Yogg-Saron ability: "Draw 5 spells."
class DomainOfYoggSaron: ICardWithHighlight {
    required init() {}

    func getCardId() -> String {
        CardIds.NonCollectible.Neutral.MastermindYoggSaron_DomainOfYoggSaronToken
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(card.type == .spell)
    }
}
