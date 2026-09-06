//
//  QueueWatcher.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/9/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

struct QueueEventArgs {
    var isInQueue: Bool
    var current: FindGameState?
    var previous: FindGameState?
}

class QueueWatcher: Watcher {
    var inQueueChanged: ((_ sender: QueueWatcher, _ args: QueueEventArgs) -> Void)?
    private var _prev: FindGameState?

    override init(delay: TimeInterval = 0.200) {
        super.init(delay: delay)
    }

    override func cleanup() {
        _prev = nil
    }

    override func update() -> Bool {
        let state = MirrorHelper.getFindGameState()
        let isInQueue = state?.rawValue ?? 0 > 0
        let wasInQueue = _prev?.rawValue ?? 0 > 0
        if isInQueue != wasInQueue {
            inQueueChanged?(self, QueueEventArgs(isInQueue: isInQueue, current: state, previous: _prev))
        }
        _prev = state
        return false
    }
}
