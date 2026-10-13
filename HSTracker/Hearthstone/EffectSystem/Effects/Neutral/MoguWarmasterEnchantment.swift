//
//  MoguWarmasterEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

//swiftlint:disable inclusive_language
// "After you play a neutral card, your next spell costs (1) less this turn."
class MoguWarmasterEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Neutral.MoguWarmaster_WarShoutEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Neutral.MoguWarmaster
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        return .sameTurn
    }

    override var effectTag: EffectTag {
        return .costModification
    }
}
//swiftlint:enable inclusive_language
