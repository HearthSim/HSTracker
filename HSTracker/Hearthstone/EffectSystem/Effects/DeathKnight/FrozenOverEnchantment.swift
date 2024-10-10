//
//  FrozenOverEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/12/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class FrozenOverEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Deathknight.FrozenOver_FrozenSolidEnchantment
    }
    
    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Deathknight.FrozenOver
    }
    
    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }
    
    override var effectTarget: EffectTarget {
        return .enemy
    }
    
    override var effectDuration: EffectDuration {
        return .nextTurn
    }
    
    override var effectTag: EffectTag {
        return .cardLock
    }
}

