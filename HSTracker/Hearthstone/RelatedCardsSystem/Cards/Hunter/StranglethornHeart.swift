//
//  StranglethornHeart.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/7/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class StranglethornHeart: ResurrectionCard {
    
    override func getCardId() -> String {
        return CardIds.Collectible.Hunter.StranglethornHeart
    }

    override func filterCard(card: Card) -> Bool {
        return card.isBeast() && card.cost >= 5
    }

    override func resurrectsMultipleCards() -> Bool {
        return true
    }

    required init() {
    }
}
