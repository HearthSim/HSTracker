//
//  TheLichKing.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/23/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class TheLichKing: ICardWithRelatedCards {
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
        CardIds.Collectible.Neutral.TheLichKing
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        lichKingCards
    }
}
