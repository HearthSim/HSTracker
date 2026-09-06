//
//  BattlegroundsLobbyInfoWatcher.swift
//  HSTracker
//
//  Created by Francisco Moraes on 7/26/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

struct BattlegroundsLobbyInfoArgs: Equatable {
    let lobbyInfo: MirrorBattlegroundsLobbyInfo?
}

class BattlegroundsLobbyInfoWatcher: Watcher {
    var change: ((_ sender: BattlegroundsLobbyInfoWatcher, _ args: BattlegroundsLobbyInfoArgs) -> Void)?
    private var _prev: BattlegroundsLobbyInfoArgs?

    override init(delay: TimeInterval = 0.200) {
        super.init(delay: delay)
    }
    
    override func cleanup() {
        _prev = nil
    }

    override func update() -> Bool {
        let value = MirrorHelper.getBattlegroundsLobbyInfo()
        let curr = BattlegroundsLobbyInfoArgs(lobbyInfo: value)
        if curr == _prev {
            return false
        }
        change?(self, curr)
        _prev = curr
        return false
    }
}
