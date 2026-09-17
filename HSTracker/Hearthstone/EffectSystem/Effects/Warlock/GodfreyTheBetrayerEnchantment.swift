//
//  GodfreyTheBetrayerEnchantment.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/17/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

/// HDT's `GodfreyTheBetrayerEnchantment`. Godfrey's Atlas burns every card drawn
/// past the hand limit into the void instead of destroying it, so the enchantment
/// stays up for the rest of the game.
///
/// It is also what tells the burned-card metadata that a burn belongs to Godfrey
/// rather than to an ordinary overdraw - see
/// `PowerGameStateParser`'s BURNED_CARD branch.
class GodfreyTheBetrayerEnchantment: EntityBasedEffect {
    override var cardId: String {
        return CardIds.NonCollectible.Neutral.GodfreytheBetrayer_GodfreysAtlasEnchantment
    }

    override var cardIdToShowInUI: String {
        return CardIds.Collectible.Warlock.GodfreyTheBetrayer
    }

    required init(entityId: Int, isControlledByPlayer: Bool) {
        super.init(entityId: entityId, isControlledByPlayer: isControlledByPlayer)
    }

    override var effectDuration: EffectDuration {
        return .permanent
    }

    override var effectTag: EffectTag {
        return .cardAmount
    }
}
