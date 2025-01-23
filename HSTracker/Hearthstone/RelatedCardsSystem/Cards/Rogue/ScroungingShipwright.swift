//
//  ScroungingShipwright.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/8/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class ScroungingShipwright: ICardWithRelatedCards {

    private let starshipPieces: [Card?] = [
        Cards.by(cardId: CardIds.Collectible.Rogue.TheGravitationalDisplacer),
        Cards.by(cardId: CardIds.Collectible.DemonHunter.ShattershardTurret),
        Cards.by(cardId: CardIds.Collectible.DemonHunter.FelfusedBattery),
        Cards.by(cardId: CardIds.Collectible.Druid.ShatariCloakfield),
        Cards.by(cardId: CardIds.Collectible.Druid.StarlightReactor),
        Cards.by(cardId: CardIds.Collectible.Deathknight.GuidingFigure),
        Cards.by(cardId: CardIds.Collectible.Deathknight.SoulboundSpire),
        Cards.by(cardId: CardIds.Collectible.Warlock.FelfireThrusters),
        Cards.by(cardId: CardIds.Collectible.Warlock.HeartOfTheLegion),
        Cards.by(cardId: CardIds.Collectible.Hunter.Biopod),
        Cards.by(cardId: CardIds.Collectible.Hunter.SpecimenClaw),
        Cards.by(cardId: CardIds.Collectible.Shaman.MissilePod),
        Cards.by(cardId: CardIds.Collectible.Paladin.UltraCapacitor),
        Cards.by(cardId: CardIds.Collectible.Warrior.YamatoCannon)
    ]

    func getCardId() -> String {
        return CardIds.Collectible.Rogue.ScroungingShipwright
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return starshipPieces.filter { card in
            if let card {
                return !card.isClass(cardClass: player.currentClass ?? .invalid)
            }
            return false
        }.sorted(by: { ($0?.cost ?? 0) < ($1?.cost ?? 0) })
    }

    required init() {
    }
}
