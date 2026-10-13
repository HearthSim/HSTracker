//
//  LarvaCard.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// Shared base for cards that give Larvae: "1-Cost Larva with a Combo that triggers a Hero Power from
// another class." One Larva per class; the player's own class is excluded. The Neutral Teal Larva
// ("No Spoilers!") is left out until its class is known.
class LarvaCard: ICardWithRelatedCards {
    private static let larvae = [
        CardIds.NonCollectible.Priest.BroodchamberTunneler_PaleLarvaToken,
        CardIds.NonCollectible.Shaman.BroodchamberTunneler_BlueLarvaToken,
        CardIds.NonCollectible.Rogue.BroodchamberTunneler_BlackLarvaToken,
        CardIds.NonCollectible.Paladin.BroodchamberTunneler_YellowLarvaToken,
        CardIds.NonCollectible.Hunter.BroodchamberTunneler_GreenLarvaToken,
        CardIds.NonCollectible.Druid.BroodchamberTunneler_BrownLarvaToken,
        CardIds.NonCollectible.Warlock.BroodchamberTunneler_PurpleLarvaToken,
        CardIds.NonCollectible.Mage.BroodchamberTunneler_CyanLarvaToken,
        CardIds.NonCollectible.Warrior.BroodchamberTunneler_RedLarvaToken,
        CardIds.NonCollectible.DemonHunter.BroodchamberTunneler_NeonLarvaToken,
        CardIds.NonCollectible.Deathknight.BroodchamberTunneler_DarkLarvaToken
    ]

    required init() {}

    func getCardId() -> String {
        fatalError("Must be overridden")
    }

    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }

    func getRelatedCards(player: Player) -> [Card?] {
        return LarvaCard.larvae
            .compactMap { Cards.any(byId: $0) }
            .filter { !$0.isClass(cardClass: player.currentClass) }
    }
}
