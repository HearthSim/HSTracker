//
//  BattlegroundsLeaderboardWatcher.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/9/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation
import Atomics

struct BattlegroundsLeaderboardArgs: Equatable {
    let hoveredEntityId: Int?
}

class BattlegroundsLeaderboardWatcher {
    var change: ((_ sender: BattlegroundsLeaderboardWatcher, _ args: BattlegroundsLeaderboardArgs) -> Void)?
    private let delay: TimeInterval
    private var _running = ManagedAtomic<Bool>(false)
    private var _watch = ManagedAtomic<Bool>(false)
    private var _prev: BattlegroundsLeaderboardArgs?
    internal var queue: DispatchQueue?

    init(delay: TimeInterval = 0.016) {
        self.delay = delay
    }
    
    func run() {
        _watch.store(true, ordering: .sequentiallyConsistent)
        if _running.load(ordering: .sequentiallyConsistent) {
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
        _watch.store(false, ordering: .sequentiallyConsistent)
    }

    private func update() {
        _running.store(true, ordering: .sequentiallyConsistent)
        while _watch.load(ordering: .sequentiallyConsistent) {
            Thread.sleep(forTimeInterval: delay)
            if !_watch.load(ordering: .sequentiallyConsistent) {
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
        _running.store(false, ordering: .sequentiallyConsistent)
    }
}
