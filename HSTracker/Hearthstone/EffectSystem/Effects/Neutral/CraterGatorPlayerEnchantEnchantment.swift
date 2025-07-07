//
//  CraterGatorPlayerEnchantEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/7/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class CraterGatorPlayerEnchantEnchantment: EntityBasedEffect {
    override var cardId: String {
        CardIds.NonCollectible.Neutral.CraterGator_CraterGatorPlayerEnchantEnchantment
    }

    override var cardIdToShowInUI: String {
        CardIds.Collectible.Neutral.CraterGator
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectTarget: EffectTarget {
        .enemy
    }

    override var effectDuration: EffectDuration {
        .nextTurn
    }

    override var effectTag: EffectTag {
        .heroModification
    }
}
