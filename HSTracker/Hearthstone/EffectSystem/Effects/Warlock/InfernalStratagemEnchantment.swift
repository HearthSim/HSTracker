//
//  InfernalStratagemEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/30/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class InfernalStratagemEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Warlock.InfernalStratagem_StrategicInfernoEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Warlock.InfernalStratagem
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectTarget: EffectTarget {
        return .myself
    }

    override var effectDuration: EffectDuration {
        return .conditional
    }

    override var effectTag: EffectTag {
        return .costModification
    }
}
