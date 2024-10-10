//
//  CenarionHoldEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/13/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class CenarionHoldEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Druid.CenarionHold_CenariOnHoldEnchantment
    }
    
    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Druid.CenarionHold
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        return EffectDuration.conditional
    }
    
    override var effectTag: EffectTag {
        return EffectTag.heroModification
    }
}
