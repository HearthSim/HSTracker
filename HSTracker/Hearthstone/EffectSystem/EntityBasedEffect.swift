//
//  EntityBasedEffect.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/12/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

public class EntityBasedEffect: IShowInGlobalEffectList {
    
    let entityId: Int
    let isControlledByPlayer: Bool
    var cardId: String? { return nil }
    
    var cardIdToShowInUI: String? { return nil }
    var cardToShowInUI: Card? {
        return Cards.by(cardId: cardIdToShowInUI ?? cardId)
    }
    
    var cardAsset: NSImage? {
        return nil // FIXME: implement
    }
    
    var showNumberInPlay: Bool { return true }
    var effectTarget: EffectTarget { return .myself }
    var uniqueEffect: Bool { return false }
    
    var effectDuration: EffectDuration {
        fatalError("Must be overridden")
    }
    
    var effectTag: EffectTag {
        fatalError("Must be overridden")
    }
    
    required init(entityId: Int, isControlledByPlayer: Bool) {
        self.entityId = entityId
        self.isControlledByPlayer = isControlledByPlayer
    }
}

