//
//  ElizaGorebladeEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/12/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class ElizaGorebladeEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Priest.ElizaGoreblade_VitalityShiftEnchantment
    }
    
    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Deathknight.ElizaGoreblade
    }
    
    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }
    
    override var effectDuration: EffectDuration {
        return .permanent
    }
    
    override var effectTag: EffectTag {
        return .minionModification
    }
}

