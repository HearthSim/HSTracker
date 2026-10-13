//
//  ElderWordForesightEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Draw a card and reduce its Cost by (2). (The next Shadow spell you play repeats this!)"
class ElderWordForesightEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Priest.ElderWordForesight_ForesightEssenceEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Priest.ElderWordForesight
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
