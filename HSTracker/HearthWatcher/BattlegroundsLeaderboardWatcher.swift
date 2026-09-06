//
//  BattlegroundsLeaderboardWatcher.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/9/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

struct BattlegroundsLeaderboardArgs: Equatable {
    let hoveredEntityId: Int?
}

class BattlegroundsLeaderboardWatcher: Watcher {
    var change: ((_ sender: BattlegroundsLeaderboardWatcher, _ args: BattlegroundsLeaderboardArgs) -> Void)?
    private var _prev: BattlegroundsLeaderboardArgs?

    override init(delay: TimeInterval = 0.016) {
        super.init(delay: delay)
    }
    
    override func cleanup() {
        _prev = nil
    }

    override func update() -> Bool {
        let value = MirrorHelper.getBattlegroundsLeaderboardHoveredEntityId()
        let curr = BattlegroundsLeaderboardArgs(hoveredEntityId: value)
        if curr == _prev {
            return false
        }
        change?(self, curr)
        _prev = curr
        return false
    }
}
