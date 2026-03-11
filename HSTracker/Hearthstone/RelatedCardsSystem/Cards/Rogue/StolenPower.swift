//
//  StolenPower.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class StolenPower: ICardWithRelatedCards {

    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Rogue.StolenPower
    }

    private let shatterCards: [Card?] = [
        Cards.by(cardId: CardIds.Collectible.Druid.WildwoodCircle),
        Cards.by(cardId: CardIds.Collectible.Hunter.SupplyRun),
        Cards.by(cardId: CardIds.Collectible.Mage.ArcaneFlow),
        Cards.by(cardId: CardIds.Collectible.Paladin.FlightManeuvers),
        Cards.by(cardId: CardIds.Collectible.Priest.Schism)
    ]

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return shatterCards
    }
}
