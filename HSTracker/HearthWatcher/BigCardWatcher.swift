//
//  BigCardWatcher.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/9/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

struct BigCardArgs: Equatable {
    var tooltipHeights: [Float]
    var enchantmentHeights: [Float]
    var cardId: String
    var zonePosition: Int
    var zoneSize: Int
    var side: Int
    var isHand: Bool
    
    init(value: MirrorBigCardState?) {
        if let value {
            tooltipHeights = value.tooltipHeights.compactMap { $0.floatValue }
            enchantmentHeights = value.enchantmentHeights.compactMap { $0.floatValue }
            cardId = value.cardId
            zonePosition = value.zonePosition.intValue
            zoneSize = value.zoneSize.intValue
            side = value.side.intValue
            isHand = value.isHand
        } else {
            tooltipHeights = [Float]()
            enchantmentHeights = [Float]()
            cardId = ""
            zonePosition = 0
            zoneSize = 0
            side = 0
            isHand = false
        }
    }
}

class BigCardWatcher: Watcher {
    var change: ((_ sender: BigCardWatcher, _ args: BigCardArgs) -> Void)?
    
    private var _prev: BigCardArgs?
    
    override init(delay: TimeInterval = 0.016) {
        super.init(delay: delay)
    }
    
    override func cleanup() {
        _prev = nil
    }

    override func update() -> Bool {
        let value = MirrorHelper.getBigCardState()
        let curr = BigCardArgs(value: value)
        if curr == _prev {
            return false
        }
        change?(self, curr)
        _prev = curr
        return false
    }

}
