//
//  FinjaTheFlyingStar.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

public class FinjaTheFlyingStar: ICardWithHighlight {
    
    required public init() {
        // Required init
    }
    
    public func getCardId() -> String {
        return CardIds.Collectible.Neutral.FinjaTheFlyingStar
    }
    
    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.isMurloc())
    }
}

public class FinjaTheFlyingStarCorePlaceholder: FinjaTheFlyingStar {
    
    public required init() {
        super.init()
    }
    
    public override func getCardId() -> String {
        return CardIds.Collectible.Neutral.FinjaTheFlyingStarCore
    }
}
