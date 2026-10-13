//
//  DomainOfYshaarjEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// "Y'Shaarj ability: Your next card costs (5) less."
class DomainOfYshaarjEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Neutral.YShaarjTitanBane_DomainOfYshaarjToken2
    }

    override var cardIdToShowInUI: String {
        return CardIds.NonCollectible.Neutral.YShaarjTitanBane_DomainOfYshaarjToken1
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
