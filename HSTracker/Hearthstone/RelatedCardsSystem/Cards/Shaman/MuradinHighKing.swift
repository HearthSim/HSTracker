//
//  MuradinHighKing.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/4/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class MuradinHighKing: ICardWithHighlight {
    func getCardId() -> String {
        CardIds.Collectible.Shaman.MuradinHighKing
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(
            card.id == CardIds.NonCollectible.Shaman.MuradinHighKing_HighKingsHammerToken
        )
    }

    required init() {}
}
