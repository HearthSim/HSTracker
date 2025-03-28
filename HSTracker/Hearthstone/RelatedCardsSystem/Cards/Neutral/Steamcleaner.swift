//
//  Steamcleaner.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

public class Steamcleaner: ICardWithHighlight {
    
    public required init() { }
    
    public func getCardId() -> String {
        return CardIds.Collectible.Neutral.Steamcleaner
    }
    
    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.isCreated)
    }
}

public class SteamcleanerCore: Steamcleaner {
    
    public required init() {
        super.init()
    }
    
    public override func getCardId() -> String {
        return CardIds.Collectible.Neutral.SteamcleanerCore
    }
}
