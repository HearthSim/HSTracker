//
//  DiscoverStateWatcher.swift
//  HSTracker
//
//  Created by Francisco Moraes on 4/2/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation

struct DiscoverStateArgs: Equatable {
    var cardId: String
    var zonePosition: Int
    var zoneSize: Int
    // The moused-over choice's entity id (GameTag.ENTITY_ID), which a card id
    // alone cannot stand in for when several offered entities share one - it is
    // how a Battlegrounds quest reward is resolved. Absent until the choice has
    // one.
    var entityId: Int?
}

class DiscoverStateWatcher: Watcher {
    var change: ((_ sender: DiscoverStateWatcher, _ args: DiscoverStateArgs) -> Void)?
    
    private var _prev: DiscoverStateArgs?

    override init(delay: TimeInterval = 0.016) {
        super.init(delay: delay)
    }
    
    override func cleanup() {
        _prev = nil
    }

    override func update() -> Bool {
        let state = MirrorHelper.getDiscoverState()
        let curr = DiscoverStateArgs(cardId: state?.cardId ?? "", zonePosition: state?.zonePosition.intValue ?? 0, zoneSize: state?.zoneSize.intValue ?? 0, entityId: state?.entityId?.intValue)
        if curr == _prev {
            return false
        }
        change?(self, curr)
        _prev = curr
        return false
    }
}
