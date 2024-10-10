//
//  DynamicFactory.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/16/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

protocol DynamicObject {
    init(entityId: Int, isControlledByPlayer: Bool)
    
    var cardId: String? { get }
}

class DynamicFactory<T: DynamicObject> {
    internal var constructors = [String: DynamicObject.Type]()

    init() {
        let subClasses = MonoHelper.withAllClasses { $0.compactMap { $0 as? DynamicObject.Type } }

        for entity in subClasses {
            let instance = entity.init(entityId: 0, isControlledByPlayer: true)
            if let cardId = instance.cardId {
                constructors[cardId] = entity
            }
        }
    }
}
