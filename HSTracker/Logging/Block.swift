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

    init(parent: Block?, id: Int) {
        self.parent = parent
        self.children = []
        self.id = id
    }

    func createChild(blockId: Int) -> Block {
        return Block(parent: self, id: blockId)
    }
}
