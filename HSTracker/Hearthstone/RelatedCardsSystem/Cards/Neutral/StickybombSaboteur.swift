//
//  StickybombSaboteur.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class StickybombSaboteur: ICardWithRelatedCards {

    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Neutral.StickybombSaboteur
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return [
            Cards.by(cardId: CardIds.NonCollectible.Neutral.StickybombSaboteur_SabotageToken)
        ]
    }
}
