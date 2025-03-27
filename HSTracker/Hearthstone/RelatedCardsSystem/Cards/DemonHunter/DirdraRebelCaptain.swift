//
//  DirdraRebelCaptain.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/8/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class DirdraRebelCaptain: CrewmateGenerator, ICardWithRelatedCards, ICardWithHighlight {
    
    func getCardId() -> String {
        return CardIds.Collectible.DemonHunter.DirdraRebelCaptain
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }
    
    func shouldHighlight(card: Card) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(crewmates.any({ c in c?.id == card.id }))
    }

    required override init() {
    }
}
