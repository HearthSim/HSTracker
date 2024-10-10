//
//  EffectFactory.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/16/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class EffectFactory: DynamicFactory<EntityBasedEffect> {
    func createFromEntity(entity: Entity, controlledByPlayer: Bool) -> EntityBasedEffect? {
        if !entity.cardId.isEmpty, let ctor = constructors[entity.cardId] {
            return ctor.init(entityId: entity.id, isControlledByPlayer: controlledByPlayer) as? EntityBasedEffect
        }

        return nil
    }
}
