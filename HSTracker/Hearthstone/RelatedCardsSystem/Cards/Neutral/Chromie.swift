//
//  Chromie.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/4/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class Chromie: ICardWithHighlight {
    func getCardId() -> String {
        CardIds.Collectible.Neutral.Chromie
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        let cardsPlayedThisGame = Set(
            AppDelegate.instance().coreManager.game.player.cardsPlayedThisMatch
                .compactMap { $0.cardId }
        )

        return HighlightColorHelper.getHighlightColor(cardsPlayedThisGame.contains(card.id))
    }

    required init() {}
}
