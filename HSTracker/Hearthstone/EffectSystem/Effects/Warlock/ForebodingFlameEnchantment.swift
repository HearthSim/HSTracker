//
//  ForebodingFlameEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/30/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class ForebodingFlameEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Warlock.ForebodingFlame_BurningLegionsBoonEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Warlock.ForebodingFlame
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectTarget: EffectTarget {
        return .myself
    }

    override var effectDuration: EffectDuration {
        return .permanent
    }

    override var effectTag: EffectTag {
        return .minionModification
    }
}
