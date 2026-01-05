//
//  TimelineAccelerator.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/5/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

public class TimelineAccelerator: ICardWithHighlight {
    
    required init() {
        
    }
    
    public func getCardId() -> String {
        return CardIds.Collectible.Neutral.TimelineAccelerator
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.isMech())
    }
}
