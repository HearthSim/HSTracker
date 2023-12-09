//
//  Choice.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/8/23.
//  Copyright © 2023 Benjamin Michotte. All rights reserved.
//

import Foundation

class Choice {
    var id: Int
    var choiceType: ChoiceType
    var chosenEntities = [Entity]()
    
    init(id: Int, choiceType: ChoiceType) {
        self.id = id
        self.choiceType = choiceType
    }
    
    func attachChosenEntity(index: Int, entity: Entity) {
        chosenEntities.append(entity)
    }
}
