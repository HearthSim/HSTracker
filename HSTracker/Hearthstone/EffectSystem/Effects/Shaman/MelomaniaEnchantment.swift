//
//  MelomaniaEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/15/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class MelomaniaEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Shaman.Melomania_MelomaniaEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Shaman.Melomania
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        return .sameTurn
    }

    override var effectTag: EffectTag {
        return .cardAmount
    }
}
