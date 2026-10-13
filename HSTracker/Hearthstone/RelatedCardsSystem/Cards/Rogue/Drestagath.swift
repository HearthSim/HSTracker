//
//  Drestagath.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Deathrattle: Draw an Old God. If you can't, get a random Old God."
class Drestagath: ICardWithRelatedCards, ICardWithHighlight {
    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Rogue.Drestagath
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return [
            Cards.any(byId: CardIds.Collectible.Neutral.MastermindYoggSaron),
            Cards.any(byId: CardIds.Collectible.Neutral.CthunEyeOfTheEmpire),
            Cards.any(byId: CardIds.Collectible.Neutral.NzothDreamsEnd),
            Cards.any(byId: CardIds.Collectible.Neutral.YshaarjTitanBane)
        ]
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.isOldGod)
    }
}
