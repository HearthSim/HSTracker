//
//  ElementalOfMadness.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Battlecry: Discover any spell with Cost equal to this minion's Attack. It costs (0) this turn."
// The bucket is the hovered copy's current Attack; without an entity, the printed Attack.
class ElementalOfMadness: StateValuePoolCard {
    private static let printedAttack = 2

    override func getCardId() -> String { CardIds.Collectible.Shaman.ElementalOfMadness }
    override var batchSize: Int { 3 }
    override var isWithReplacement: Bool { false }
    override func isInPool(_ card: Card) -> Bool { card.type == .spell }
    override var poolCacheKey: String { "spells" }

    override func targetCost(player: Player, hoveredEntity: Entity?) -> Int? {
        if let hoveredEntity, hoveredEntity.has(tag: .atk) {
            return hoveredEntity[.atk]
        }
        return ElementalOfMadness.printedAttack
    }
}
