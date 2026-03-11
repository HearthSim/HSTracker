//
//  TichondriusEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

class TichondriusEnchantment: EntityBasedEffect {

    override var cardId: String {
        return CardIds.NonCollectible.DemonHunter.Tichondrius_DemonicSummoningEnchantment
    }

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.DemonHunter.TichondriusCorePlaceholder
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        return .conditional
    }

    override var effectTag: EffectTag {
        return .costModification
    }
}
