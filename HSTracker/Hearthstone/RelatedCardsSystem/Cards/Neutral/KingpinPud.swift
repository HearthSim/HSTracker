//
//  KingpinPud.swift
//  HSTracker
//
//  Created by Francisco Moraes on 5/22/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class KingpinPud: ResurrectionCard {
    private let ogreGangs: [String] = [
        CardIds.Collectible.Neutral.OgreGangOutlaw,
        CardIds.Collectible.Neutral.OgreGangRider,
        CardIds.Collectible.Neutral.OgreGangAce,
        CardIds.Collectible.Neutral.BoulderfistOgreCore,
        CardIds.Collectible.Neutral.BoulderfistOgreLegacy,
        CardIds.Collectible.Neutral.BoulderfistOgreVanilla
    ]
    
    required init() {}

    override func getCardId() -> String {
        return CardIds.Collectible.Neutral.KingpinPud
    }
    
    override func filterCard(card: Card) -> Bool {
        return ogreGangs.contains(card.id)
    }
    
    override func resurrectsMultipleCards() -> Bool {
        return true
    }
}
