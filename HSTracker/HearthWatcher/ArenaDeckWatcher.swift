//
//  ArenaWatcher.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/9/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class ArenaDeckWatcher {
    private let delay: TimeInterval

    private(set) var selectedDeck: MirrorDeck?
    private(set) var selectedDeckId: Int64 = 0
    
    private var _running = false
    private var _watch = false
    internal var queue: DispatchQueue?

    init(delay: TimeInterval = 0.500) {
        self.delay = delay
    }
    
    func run() {
        _watch = true
        if _running {
            return
        }
        if queue == nil {
            queue = DispatchQueue(label: "net.hearthsim.hstracker.watchers.\(type(of: self))",
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

    func update() {
        _running = true
        while _watch {
            guard let arenaInfo = MirrorHelper.getArenaDeck() else {
                Thread.sleep(forTimeInterval: delay)
                continue
            }

            selectedDeck = arenaInfo.deck

            Thread.sleep(forTimeInterval: delay)
        }
        _running = false
    }
}
