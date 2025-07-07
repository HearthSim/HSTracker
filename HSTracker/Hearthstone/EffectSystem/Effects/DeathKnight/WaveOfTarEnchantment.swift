//
//  WaveOfTarEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/7/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

class WaveOfTarEnchantment: EntityBasedEffect {
    override var cardId: String {
        CardIds.NonCollectible.Deathknight.WaveofTar_StuckEnchantment
    }

    override var cardIdToShowInUI: String {
        CardIds.Collectible.Deathknight.WaveOfTar
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectTarget: EffectTarget {
        .enemy
    }

    override var effectDuration: EffectDuration {
        .conditional
    }

    override var effectTag: EffectTag {
        .costModification
    }
}
