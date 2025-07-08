//
//  CrystalCoreEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/8/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class CrystalCoreEnchantment: EntityBasedEffect {
    override var cardId: String {
        CardIds.NonCollectible.Neutral.TheCavernsBelow_CrystallizedTokenUNGORO1
    }

    override var cardIdToShowInUI: String {
        CardIds.NonCollectible.Rogue.TheCavernsBelow_CrystalCoreTokenUNGORO
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var uniqueEffect: Bool { true }
    override var effectDuration: EffectDuration { .permanent }
    override var effectTag: EffectTag { .minionModification }
}
