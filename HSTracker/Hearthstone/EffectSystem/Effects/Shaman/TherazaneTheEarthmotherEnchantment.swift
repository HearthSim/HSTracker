//
//  TherazaneTheEarthmotherEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Battlecry: Your next spell of each school casts twice."
class TherazaneTheEarthmotherEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Neutral.TherazanetheEarthmother_SpellsOfASchoolsCastTwiceEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Shaman.TherazaneTheEarthmother
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
