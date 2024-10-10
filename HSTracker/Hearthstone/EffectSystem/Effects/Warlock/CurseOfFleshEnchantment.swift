//
//  CurseOfFleshEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/15/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class CurseOfFleshEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Warlock.CurseofFlesh_CurseOfFleshEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Warlock.CurseOfFlesh
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectTarget: EffectTarget {
        return .enemy
    }

    override var effectDuration: EffectDuration {
        return .nextTurn
    }

    override var effectTag: EffectTag {
        return .costModification
    }
}
