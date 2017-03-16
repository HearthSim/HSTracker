//
//  DeckWatcher.swift
//  HSTracker
//
//  Created by Istvan Fehervari on 19/01/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

class Watcher {
    internal var isRunning = false
    internal var queue: DispatchQueue?
    internal var refreshInterval: TimeInterval = 0.5

    func start() {
        if isRunning {
            return
        }

        Log.info?.message("Starting \(type(of: self))")

        queue = DispatchQueue(label: "be.michotte.hstracker.watchers.\(type(of: self))",
            attributes: [])
        if let queue = queue {
            isRunning = true
            queue.async { [weak self] in
                self?.run()
            }
        }
    }

    func stop() {
        isRunning = false
        Log.info?.message("Stopping \(type(of: self))")

        clean()
    }

    internal func run() {}
    internal func clean() {}
}

class DeckWatcher: Watcher {
    private(set) var selectedDeckId: Int64 = 0

    override func run() {
        while isRunning {
            guard let hearthstone = (NSApp.delegate as? AppDelegate)?.hearthstone,
                  let mirror = hearthstone.mirror,
                  let deckId = mirror.getSelectedDeck() as? Int64 else {
                Thread.sleep(forTimeInterval: refreshInterval)
                continue
            }

            if deckId > 0 {
                self.selectedDeckId = deckId
            }

            Thread.sleep(forTimeInterval: refreshInterval)
        }

        queue = nil
    }
}

class ArenaDeckWatcher: DeckWatcher {
    
    private(set) var selectedDeck: MirrorDeck?
    
    override var selectedDeckId: Int64 {
        return selectedDeck?.id as Int64? ?? 0
    }
    
    override func run() {
        while isRunning {
            guard let hearthstone = (NSApp.delegate as? AppDelegate)?.hearthstone,
                let mirror = hearthstone.mirror,
                let arenaInfo = mirror.getArenaDeck() else {
                Thread.sleep(forTimeInterval: refreshInterval)
                continue
            }
            
            self.selectedDeck = arenaInfo.deck
            
            Thread.sleep(forTimeInterval: refreshInterval)
        }

        queue = nil
    }
    
}
