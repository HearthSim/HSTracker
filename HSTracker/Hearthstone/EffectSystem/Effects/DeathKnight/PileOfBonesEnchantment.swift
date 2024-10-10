//
//  PileOfBonesEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/12/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

public class PileOfBonesEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Deathknight.PileofBones_PileOfBonesEnchantment
    }
    
    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Deathknight.PileOfBones
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        return EffectDuration.conditional
    }
    
    override var effectTag: EffectTag {
        return EffectTag.summon
    }
}
