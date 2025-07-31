//
//  DiscoverStateWatcher.swift
//  HSTracker
//
//  Created by Francisco Moraes on 4/2/25.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import Foundation
import Atomics

struct DiscoverStateArgs: Equatable {
    var cardId: String
    var zonePosition: Int
    var zoneSize: Int
}

class DiscoverStateWatcher {
    let delay: TimeInterval
    var change: ((_ sender: DiscoverStateWatcher, _ args: DiscoverStateArgs) -> Void)?
    
    private var _running = ManagedAtomic<Bool>(false)
    private var _watch = ManagedAtomic<Bool>(false)
    private var _prev: DiscoverStateArgs?
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
            queue = DispatchQueue(label: "\(type(of: self))",
                                  attributes: [])
        }
        if let queue = queue {
            queue.async { [weak self] in
                guard let self else { return }
                Thread.current.name = queue.label
                self.update()
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
            
            let state = MirrorHelper.getDiscoverState()
            let curr = DiscoverStateArgs(cardId: state?.cardId ?? "", zonePosition: state?.zonePosition.intValue ?? 0, zoneSize: state?.zoneSize.intValue ?? 0)
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
