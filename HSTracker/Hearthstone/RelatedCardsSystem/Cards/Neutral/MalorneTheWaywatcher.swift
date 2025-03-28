//
//  MalorneTheWaywatcher.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

public class MalorneTheWaywatcher: ICardWithRelatedCards {
    
    // Properties
    private let wildGods: [Card?] = [
        Cards.any(byId: CardIds.Collectible.Deathknight.Ursoc),
        Cards.any(byId: CardIds.Collectible.DemonHunter.Omen),
        Cards.any(byId: CardIds.Collectible.Druid.ForestLordCenarius),
        Cards.any(byId: CardIds.Collectible.Hunter.Goldrinn),
        Cards.any(byId: CardIds.Collectible.Mage.Aessina),
        Cards.any(byId: CardIds.Collectible.Paladin.Ursol),
        Cards.any(byId: CardIds.Collectible.Priest.AvianaElunesChosen),
        Cards.any(byId: CardIds.Collectible.Rogue.Ashamane),
        Cards.any(byId: CardIds.Collectible.Shaman.Ohnahra),
        Cards.any(byId: CardIds.Collectible.Warlock.Agamaggan),
        Cards.any(byId: CardIds.Collectible.Warrior.Tortolla)
    ]
    
    // Initializer
    required public init() {
        // Required init
    }
    
    // Methods
    public func getCardId() -> String {
        return CardIds.Collectible.Neutral.MalorneTheWaywatcher
    }
    
    func shouldShowForOpponent(opponent: Player) -> Bool {
        return false
    }
    
    func getRelatedCards(player: Player) -> [Card?] {
        return wildGods
    }
}
