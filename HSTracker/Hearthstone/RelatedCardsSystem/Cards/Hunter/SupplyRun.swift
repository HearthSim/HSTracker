//
//  SupplyRun.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class SupplyRun: ICardWithHighlight {

    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Hunter.SupplyRun
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.type == .minion)
    }
}

class SupplyRunShattered: SupplyRun {

    override func getCardId() -> String {
        return CardIds.NonCollectible.Hunter.SupplyRun_SupplyRunToken1
    }
}
