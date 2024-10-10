//
//  CarrionStudiesEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/14/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class CarrionStudiesEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Neutral.CarrionStudies_CarrionStudiesEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Hunter.CarrionStudies
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        return .conditional
    }

    override var effectTag: EffectTag {
        return .costModification
    }
}
