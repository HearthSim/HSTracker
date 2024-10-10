//
//  ThornmantleMusicianEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/14/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class ThornmantleMusicianEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Hunter.ThornmantleMusician_ThornmantlesMuseEnchantment1
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Hunter.ThornmantleMusician
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        return .conditional
    }

    override var effectTag: EffectTag {
        return .minionModification
    }
}
