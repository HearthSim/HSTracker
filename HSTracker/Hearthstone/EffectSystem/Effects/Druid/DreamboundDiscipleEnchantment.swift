//
//  DreamboundDiscipleEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class DreamboundDiscipleEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Druid.DreamboundDisciple_DreamboundEnchantment
    }
    
    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Druid.DreamboundDisciple
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        return .conditional
    }

    override var effectTag: EffectTag {
        return .heroModification
    }
}
