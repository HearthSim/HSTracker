//
//  SelectiveBreeder.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/20/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class SelectiveBreeder: ICardWithHighlight {
    required init() {
    }
    
    func getCardId() -> String {
        CardIds.Collectible.Hunter.SelectiveBreederCorePlaceholder
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(card.isBeast())
    }
}

class SelectiveBreederLegacy: SelectiveBreeder {
    override func getCardId() -> String {
        CardIds.Collectible.Hunter.SelectiveBreederLegacy
    }
}
