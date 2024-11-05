//
//  DynamicFactory.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/16/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class DynamicFactory<T> {
    internal var constructors = [String: T.Type]()

    init() {
        let subClasses = ReflectionHelper.getActiveEffectClasses()

        for entity in subClasses {
            let instance = entity.init(entityId: 0, isControlledByPlayer: true)
            if let cardId = instance.cardId {
                constructors[cardId] = entity as? T.Type
            }
        }
    }
}
