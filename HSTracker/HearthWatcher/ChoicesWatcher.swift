//
//  ChoicesWatcher.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/9/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

struct ChoicesWatcherArgs: Equatable {
    var currentChoice: MirrorCardChoices?
    
    init(choice: MirrorCardChoices?) {
        currentChoice = choice
    }
    
    static func == (lhs: ChoicesWatcherArgs, rhs: ChoicesWatcherArgs) -> Bool {
        if lhs.currentChoice == nil && rhs.currentChoice == nil {
            return true
        }
        
        guard let lcc = lhs.currentChoice, let rcc = rhs.currentChoice else {
            return false
        }
        
        return lcc.isVisible == rcc.isVisible && lcc.cards == rcc.cards
    }
}

class ChoicesWatcher: Watcher {
    var change: ((_ sender: ChoicesWatcher, _ args: ChoicesWatcherArgs) -> Void)?
    
    private var _prev: ChoicesWatcherArgs?

    override init(delay: TimeInterval = 0.016) {
        super.init(delay: delay)
    }
    
    override func cleanup() {
        _prev = nil
    }

    override func update() -> Bool {
        let value = MirrorHelper.getCardChoices()
        let curr = ChoicesWatcherArgs(choice: value)
        if curr == _prev {
            return false
        }
        change?(self, curr)
        _prev = curr
        return false
    }
}
