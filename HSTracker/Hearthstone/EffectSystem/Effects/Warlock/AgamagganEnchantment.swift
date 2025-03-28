//
//  AgamagganEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/27/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class AgamagganEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Neutral.Agamaggan_CorruptedThornsEnchantment1
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Warlock.Agamaggan
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var uniqueEffect: Bool {
        return true
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
