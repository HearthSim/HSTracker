//
//  TalanjiOfTheGraves.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/4/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

class TalanjiOfTheGraves: ICardWithHighlight, ICardWithRelatedCards {
    func getCardId() -> String {
        CardIds.Collectible.Deathknight.TalanjiOfTheGraves
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        HighlightColorHelper.getHighlightColor(
            card.id == CardIds.NonCollectible.Deathknight.TalanjioftheGraves_BwonsamdiToken
        )
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        boons
    }

    private let boons: [Card?] = [
        Cards.by(cardId: CardIds.NonCollectible.Deathknight.TalanjioftheGraves_BoonOfPowerToken),
        Cards.by(cardId: CardIds.NonCollectible.Deathknight.TalanjioftheGraves_BoonOfLongevityToken),
        Cards.by(cardId: CardIds.NonCollectible.Deathknight.TalanjioftheGraves_BoonOfSpeedToken)
    ]

    required init() {}
}

class WhatBefellZandalar: ICardWithRelatedCards {
    func getCardId() -> String {
        CardIds.NonCollectible.Deathknight.TalanjioftheGraves_WhatBefellZandalarToken
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        boons
    }

    private let boons: [Card?] = [
        Cards.by(cardId: CardIds.NonCollectible.Deathknight.TalanjioftheGraves_BoonOfPowerToken),
        Cards.by(cardId: CardIds.NonCollectible.Deathknight.TalanjioftheGraves_BoonOfLongevityToken),
        Cards.by(cardId: CardIds.NonCollectible.Deathknight.TalanjioftheGraves_BoonOfSpeedToken)
    ]

    required init() {}
}
