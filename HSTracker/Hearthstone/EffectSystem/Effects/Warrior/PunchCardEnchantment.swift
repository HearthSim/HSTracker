//
//  PunchCardEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/15/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class PunchCardEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Warrior.PunchCard_PunchedInEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Warrior.PunchCard
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        return .sameTurn
    }

    override var effectTag: EffectTag {
        return .heroModification
    }
}
