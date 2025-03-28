//
//  SpiritGuide.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

public class SpiritGuide: ICardWithHighlight {
    
    public required init() { }
    
    public func getCardId() -> String {
        return CardIds.Collectible.Priest.SpiritGuide
    }
    
    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(
            card.spellSchool == SpellSchool.holy,
            card.spellSchool == SpellSchool.shadow
        )
    }
}

public class SpiritGuideCorePlaceholder: SpiritGuide {
    
    public required init() {
        super.init()
    }
    
    public override func getCardId() -> String {
        return CardIds.Collectible.Priest.SpiritGuideCore
    }
}
