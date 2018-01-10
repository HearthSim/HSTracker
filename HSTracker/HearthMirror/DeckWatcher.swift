//
//  DeckWatcher.swift
//  HSTracker
//
//  Created by Istvan Fehervari on 19/01/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation
import HearthMirror

class Watcher {
    internal var isRunning = false
    internal var queue: DispatchQueue?
    internal var refreshInterval: TimeInterval = 0.5

    func startWatching() {
        if isRunning {
            return
        }

        logger.info("Starting \(type(of: self))")

        queue = DispatchQueue(label: "net.hearthsim.hstracker.watchers.\(type(of: self))",
            attributes: [])
        if let queue = queue {
            isRunning = true
            queue.async { [weak self] in
                self?.run()
            }
        }
    }

    func stopWatching() {
        isRunning = false
        logger.info("Stopping \(type(of: self))")

        clean()
    }

    internal func run() {}
    internal func clean() {}
}

class DeckWatcher: Watcher {
    private(set) static var selectedDeckId: Int64 = 0
	
	static let _instance = DeckWatcher()
	
	static func start() {
		_instance.startWatching()
	}
	
	static func stop() {
		_instance.stopWatching()
	}

    override func run() {
        while isRunning {
            guard let deckId = MirrorHelper.getSelectedDeck() else {
                Thread.sleep(forTimeInterval: refreshInterval)
                continue
            }

            if deckId > 0 {
                if deckId != DeckWatcher.selectedDeckId {
                    logger.info("found deck id: \(deckId)")
                }
                DeckWatcher.selectedDeckId = deckId
            }

            Thread.sleep(forTimeInterval: refreshInterval)
        }

        queue = nil
    }
}

class ArenaDeckWatcher: Watcher {
    
    private(set) static var selectedDeck: MirrorDeck?
    
    private(set) static var selectedDeckId: Int64 = 0
	
	static let _instance = ArenaDeckWatcher()
	
	static func start() {
		_instance.startWatching()
	}
	
	static func stop() {
		_instance.stopWatching()
	}
    
    override func run() {
        while isRunning {
            guard let arenaInfo = MirrorHelper.getArenaDeck() else {
                Thread.sleep(forTimeInterval: refreshInterval)
                continue
            }
            
            ArenaDeckWatcher.selectedDeck = arenaInfo.deck
            
            Thread.sleep(forTimeInterval: refreshInterval)
        }

        queue = nil
    }
    
}
