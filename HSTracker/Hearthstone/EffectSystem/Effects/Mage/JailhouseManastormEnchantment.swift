//
//  JailhouseManastormEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/12/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class JailhouseManastormEnchantment: EntityBasedEffect {

    override var cardId: String {
        return CardIds.NonCollectible.Mage.JailhouseManastorm_ManastormSummoningEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Mage.JailhouseManastorm
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        return .permanent
    }

    override var effectTag: EffectTag {
        return .summon
    }
}
