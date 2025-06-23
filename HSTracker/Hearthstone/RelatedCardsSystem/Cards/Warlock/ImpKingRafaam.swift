//
//  ImpKingRafaam.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/23/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class ImpKingRafaam: ResurrectionCard {
    required init() {}

    override func getCardId() -> String {
        CardIds.Collectible.Warlock.ImpKingRafaam
    }

    override func filterCard(card: Card) -> Bool {
        card.mechanics.contains("IMP")
    }

    override func resurrectsMultipleCards() -> Bool {
        true
    }
}

class ImpKingRafaamInfused: ImpKingRafaam {
    override func getCardId() -> String {
        CardIds.NonCollectible.Warlock.ImpKingRafaam_ImpKingRafaamToken
    }
}

class ImpKingRafaamCorePlaceholder: ImpKingRafaam {
    override func getCardId() -> String {
        CardIds.Collectible.Warlock.ImpKingRafaamCorePlaceholder
    }
}
