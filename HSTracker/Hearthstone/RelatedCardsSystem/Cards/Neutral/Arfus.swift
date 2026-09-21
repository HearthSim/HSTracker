//
//  Arfus.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/21/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Deathrattle: Add a random Lich King card to your hand."
class Arfus: ICardWithRelatedCards {
    let lichKingCards: [Card?] = [
        Cards.by(cardId: CardIds.NonCollectible.Deathknight.TheLichKing_DeathCoilToken),
        Cards.by(cardId: CardIds.NonCollectible.Deathknight.TheLichKing_ObliterateToken),
        Cards.by(cardId: CardIds.NonCollectible.Deathknight.TheLichKing_DeathGripToken),
        Cards.by(cardId: CardIds.NonCollectible.Deathknight.TheLichKing_DeathAndDecayToken),
        Cards.by(cardId: CardIds.NonCollectible.Deathknight.TheLichKing_AntiMagicShellToken2),
        Cards.by(cardId: CardIds.NonCollectible.Deathknight.TheLichKing_DoomPactToken),
        Cards.by(cardId: CardIds.NonCollectible.Deathknight.TheLichKing_ArmyOfTheFrozenThroneToken),
        Cards.by(cardId: CardIds.NonCollectible.Deathknight.TheLichKing_FrostmourneToken)
    ]

    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Neutral.Arfus
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return lichKingCards
    }
}

class ArfusCorePlaceholder: Arfus {
    override func getCardId() -> String {
        return CardIds.Collectible.Neutral.ArfusCorePlaceholder
    }
}
