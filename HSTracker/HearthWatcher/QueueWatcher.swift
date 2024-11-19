//
//  QueueWatcher.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/9/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation
import Atomics

struct QueueEventArgs {
    var isInQueue: Bool
    var current: FindGameState?
    var previous: FindGameState?
}

class QueueWatcher {
    private let delay: TimeInterval
    internal var queue: DispatchQueue?
    var inQueueChanged: ((_ sender: QueueWatcher, _ args: QueueEventArgs) -> Void)?
    private var _running = ManagedAtomic<Bool>(false)
    private var _watch = ManagedAtomic<Bool>(false)
    private var _prev: FindGameState?
        
    init(delay: TimeInterval = 0.200) {
        
        self.delay = delay
    }
    
    func run() {
        _watch.store(true, ordering: .sequentiallyConsistent)
        if _running.load(ordering: .sequentiallyConsistent) {
            return
        }
        if queue == nil {
            queue = DispatchQueue(label: "\(type(of: self))",
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
            let state = MirrorHelper.getFindGameState()
            let isInQueue = state?.rawValue ?? 0 > 0
            let wasInQueue = _prev?.rawValue ?? 0 > 0
            if isInQueue != wasInQueue {
                inQueueChanged?(self, QueueEventArgs(isInQueue: isInQueue, current: state, previous: _prev))
            }
            _prev = state
        }
        _prev = nil
        _running.store(false, ordering: .sequentiallyConsistent)
    }
}
