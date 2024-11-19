//
//  ArenaWatcher.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/9/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation
import Atomics

class ArenaDeckWatcher {
    private let delay: TimeInterval

    private(set) var selectedDeck: MirrorDeck?
    private(set) var selectedDeckId: Int64 = 0
    
    private var _running = ManagedAtomic<Bool>(false)
    private var _watch = ManagedAtomic<Bool>(false)
    internal var queue: DispatchQueue?

    init(delay: TimeInterval = 0.500) {
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

    func update() {
        _running.store(true, ordering: .sequentiallyConsistent)
        while _watch.load(ordering: .sequentiallyConsistent) {
            guard let arenaInfo = MirrorHelper.getArenaDeck() else {
                Thread.sleep(forTimeInterval: delay)
                continue
            }

            selectedDeck = arenaInfo.deck

            Thread.sleep(forTimeInterval: delay)
        }
        _running .store(false, ordering: .sequentiallyConsistent)
    }
}
