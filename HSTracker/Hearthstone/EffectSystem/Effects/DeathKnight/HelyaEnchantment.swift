//
//  HelyaEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/12/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

public class HelyaEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Deathknight.Helya_HelyaEnchantment
    }
    
    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Deathknight.Helya
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }
    
    override var effectTarget: EffectTarget {
        return EffectTarget.enemy
    }

    override var effectDuration: EffectDuration {
        return EffectDuration.permanent
    }
    
    override var effectTag: EffectTag {
        return EffectTag.cardActivation
    }
}
