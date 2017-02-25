//
//  DeckWatcher.swift
//  HSTracker
//
//  Created by Istvan Fehervari on 19/01/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation

class DeckWatcher {

    private var isRunning = false
    private var _selectedDeckId: Int64 = 0

    private var queue: DispatchQueue?

    var selectedDeckId: Int64 {
        return _selectedDeckId
    }

    func start() {
        if isRunning {
            return
        }

        queue = DispatchQueue(label: "be.michotte.hstracker.watchers.deck", attributes: [])
        if let queue = queue {
            isRunning = true
            queue.async { [weak self] in
                self?.readSelectedDeck()
            }
        }
    }

    func stop() {
        isRunning = false
    }

    func readSelectedDeck() {
        while isRunning {
            guard let hearthstone = (NSApp.delegate as? AppDelegate)?.hearthstone,
                  let mirror = hearthstone.mirror,
                  let deckId = mirror.getSelectedDeck() as? Int64 else {
                Thread.sleep(forTimeInterval: 0.4)
                continue
            }

            self._selectedDeckId = deckId > 0 ? deckId : self._selectedDeckId

            Thread.sleep(forTimeInterval: 0.4)
        }
    }
}
