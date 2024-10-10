//
//  DeepminerBrannEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/15/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class DeepminerBrannEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Warrior.DeepminerBrann_DeepminingEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Warrior.DeepminerBrann
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        return .permanent
    }

    override var effectTag: EffectTag {
        return .cardActivation
    }
}
