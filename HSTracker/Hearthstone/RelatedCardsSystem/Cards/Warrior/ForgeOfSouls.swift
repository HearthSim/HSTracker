//
//  ForgeOfSouls.swift
//  HSTracker
//
//  Created by Francisco Moraes on 6/9/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class ForgeOfSouls: ICardWithHighlight {

    required init() {}

    func getCardId() -> String {
        return CardIds.Collectible.Warrior.ForgeOfSouls
    }

    func shouldHighlight(card: Card, deck: [Card]) -> HighlightColor {
        return HighlightColorHelper.getHighlightColor(card.type == .weapon)
    }
}

class ForgeOfSoulsCore: ForgeOfSouls {

    override func getCardId() -> String {
        return CardIds.Collectible.Warrior.ForgeOfSoulsCorePlaceholder
    }
}
