//
//  MagicalDollhouseEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/13/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class MagicalDollhouseEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Druid.MagicalDollhouse_MagicalHarvestEnchantment
    }
    
    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Druid.MagicalDollhouse
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        return EffectDuration.sameTurn
    }
    
    override var effectTag: EffectTag {
        return EffectTag.spellDamage
    }
}
