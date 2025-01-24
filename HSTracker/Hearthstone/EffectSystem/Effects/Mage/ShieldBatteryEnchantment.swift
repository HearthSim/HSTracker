//
//  ShieldBatteryEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/24/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class ShieldBatteryEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Neutral.ShieldBattery_KhalaiIngenuityEnchantment
    }

    override var cardIdToShowInUI: String? {
        return CardIds.Collectible.Mage.ShieldBattery
    }

    override var effectDuration: EffectDuration {
        return .conditional
    }

    override var effectTag: EffectTag {
        return .costModification
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }
}
