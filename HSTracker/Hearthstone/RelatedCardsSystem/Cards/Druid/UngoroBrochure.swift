//
//  UngoroBrochure.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/20/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class UngoroBrochure: ICardWithHighlight {
    func getCardId() -> String {
        return CardIds.Collectible.Druid.UngoroBrochure
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.type == CardType.minion)
    }

    required init() {}
}

class UngoroBrochureSpell: ICardWithHighlight {
    func getCardId() -> String {
        return CardIds.NonCollectible.Druid.UnGoroBrochure_DalaranBrochureToken
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.type == CardType.spell)
    }

    required init() {}
}
