//
//  ChitinousPlatingEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/13/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

public class ChitinousPlatingEnchantment: EntityBasedEffect {
    public override var cardId: String {
        return CardIds.NonCollectible.Druid.ChitinousPlating_MoltingEnchantment
    }
    
    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Druid.ChitinousPlating
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    public override var effectDuration: EffectDuration {
        return EffectDuration.nextTurn
    }
    
    public override var effectTag: EffectTag {
        return EffectTag.cardActivation
    }
}
