//
//  BoompistolBullyEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/15/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class BoompistolBullyEnchantment: EntityBasedEffect {
    // Properties
    override var cardId: String {
        return CardIds.NonCollectible.Neutral.BoompistolBully_SmokescreenEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Neutral.BoompistolBully
    }

    // Initializer
    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    // Computed properties
    override var effectTarget: EffectTarget {
        return .enemy
    }

    override var effectDuration: EffectDuration {
        return .nextTurn
    }

    override var effectTag: EffectTag {
        return .costModification
    }
}
