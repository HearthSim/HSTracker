//
//  Block.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 5/12/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class Block {
    let parent: Block?
    var children: [Block]
    let id: Int
    let type: String?
    let cardId: String?
    let target: String?
    
    let triggerKeyword: String?
    
    var sourceEntityId = 0
    var dredgeCounter = 0
    
    var hasFullEntityHeroPackets = false
    
    var entityDiscardedByArchivist: Entity?
    
    var entitiesCreatedInDeck = [(entity: Entity, ids: Set<Int>)]()
    
    var isTradeableAction = false
    
    var hideShowEntities = false

    // Entities revealed by a Soul Fermenter resummon, with only the tags from their SHOW_ENTITY lines,
    // taken before later effects in the same block change these values
    var soulFermenterRevealedEntities = [Entity]()
   
    init(parent: Block?, id: Int, type: String?, cardId: String?, target: String?, trigger: String?) {
        self.parent = parent
        self.children = []
        self.id = id
        self.type = type
        self.cardId = cardId
        self.target = target
        self.triggerKeyword = trigger
    }

    func createChild(blockId: Int, type: String?, cardId: String?, target: String?, trigger: String?) -> Block {
        return Block(parent: self, id: blockId, type: type, cardId: cardId, target: target, trigger: trigger)
    }
}
