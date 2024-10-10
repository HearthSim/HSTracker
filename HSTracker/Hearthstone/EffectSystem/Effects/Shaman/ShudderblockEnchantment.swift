//
//  ShudderblockEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/15/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class ShudderblockEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Shaman.Shudderblock_ReadyForActionEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Shaman.Shudderblock
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        return .conditional
    }

    override var effectTag: EffectTag {
        return .cardActivation
    }
}
