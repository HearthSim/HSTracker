//
//  SpecialShopChoicesStateWatcher.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/25/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

struct SpecialShopChoicesArgs: Equatable {
    static func == (lhs: SpecialShopChoicesArgs, rhs: SpecialShopChoicesArgs) -> Bool {
        if lhs.isActive != rhs.isActive {
            return false
        }
        
        if lhs.mousedOverSlot != rhs.mousedOverSlot {
            return false
        }
        
        if lhs.boardCards.count != rhs.boardCards.count {
            return false
        }
        
        for (i, thisCard) in lhs.boardCards.enumerated() {
            let otherCard = rhs.boardCards[i]
            if thisCard.entityId != otherCard.entityId {
                return false
            }
            if thisCard.hovered != otherCard.hovered {
                return false
            }
        }
        return true
    }

    let isActive: Bool
    let boardCards: [MirrorBoardCard]
    let mousedOverSlot: Int
}

class SpecialShopChoicesStateWatcher: Watcher {
    var change: ((_ sender: SpecialShopChoicesStateWatcher, _ args: SpecialShopChoicesArgs) -> Void)?
    private var _prev: SpecialShopChoicesArgs?
    
    override init(delay: TimeInterval = 0.200) {
        super.init(delay: delay)
    }
    
    override func cleanup() {
        _prev = nil
    }

    override func update() -> Bool {
        let state = MirrorHelper.getSpecialShopChoiceState()
        let curr = SpecialShopChoicesArgs(isActive: state?.isActive ?? false, boardCards: state?.boardCards ?? [MirrorBoardCard](), mousedOverSlot: state?.mousedOverSlot.intValue ?? -1)
        if curr == _prev {
            return false
        }
        change?(self, curr)
        _prev = curr
        return false
    }
}
