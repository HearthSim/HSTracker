//
//  NaralexHeraldOfTheFlights.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

public class NaralexHeraldOfTheFlights: ICardWithHighlight {
    
    required public init() {
        // Required init
    }
    
    public func getCardId() -> String {
        return CardIds.Collectible.Neutral.NaralexHeraldOfTheFlights // Kept CardIds as-is
    }
    
    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.isDragon())
    }
}
