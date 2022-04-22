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
    var hasFullEntityHeroPackets: Bool
    var sourceEntityId = 0
    var dredgeCounter = 0

    init(parent: Block?, id: Int, type: String?, cardId: String?) {
        self.parent = parent
        self.children = []
        self.id = id
        self.type = type
        self.cardId = cardId
        self.hasFullEntityHeroPackets = false
    }

    func createChild(blockId: Int, type: String?, cardId: String?) -> Block {
        return Block(parent: self, id: blockId, type: type, cardId: cardId)
    }
}
