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

class BattlegroundsLeaderboardWatcher {
    var change: ((_ sender: BattlegroundsLeaderboardWatcher, _ args: BattlegroundsLeaderboardArgs) -> Void)?
    private let delay: TimeInterval
    private var _running = false
    private var _watch = false
    private var _prev: BattlegroundsLeaderboardArgs?
    internal var queue: DispatchQueue?

    init(delay: TimeInterval = 0.016) {
        self.delay = delay
    }
    
    func run() {
        _watch = true
        if _running {
            return
        }
        if queue == nil {
            queue = DispatchQueue(label: "(type(of: self))",
                                  attributes: [])
        }
        if let queue = queue {
            queue.async { [weak self] in
                Thread.current.name = queue.label
                self?.update()
            }
        }
    }
    
    func stop() {
        _watch = false
    }

    private func update() {
        _running = true
        while _watch {
            Thread.sleep(forTimeInterval: delay)
            if !_watch {
                break
            }
            
            let value = MirrorHelper.getBattlegroundsLeaderboardHoveredEntityId()
            let curr = BattlegroundsLeaderboardArgs(hoveredEntityId: value)
            if curr == _prev {
                continue
            }
            change?(self, curr)
            _prev = curr
        }
        _prev = nil
        _running = false
    }
}
