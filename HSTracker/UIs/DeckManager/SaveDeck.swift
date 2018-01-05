//
//  SaveDeck.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 24/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import RealmSwift
import AppKit

protocol SaveDeckDelegate: class {
    func deckSaveSaved()
    func deckSaveCanceled()
}

class SaveDeck: NSWindowController {

    @IBOutlet weak var deckName: NSTextField!

    var deck: Deck?
    var cards: [Card]?
    var exists = false
    weak private var _delegate: SaveDeckDelegate?

    func setDelegate(_ delegate: SaveDeckDelegate) {
        _delegate = delegate
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        deckName.stringValue = deck!.name 

        if let deck = RealmHelper.getDeck(with: deck!.deckId) {
			self.deck = deck
			exists = true
        } else {
            logger.error("Can not fetch deck")
        }
    }

    // MARK: - Actions
    @IBAction func save(_ sender: AnyObject) {
        guard let deck = deck, let cards = cards, cards.isValidDeck() else { return }

		if self.exists {
			RealmHelper.rename(deck: deck, to: deckName.stringValue)
		} else {
			deck.name = deckName.stringValue
		}
        self.saveDeck(update: exists)
    }

    @IBAction func cancel(_ sender: AnyObject) {
        self._delegate?.deckSaveCanceled()
    }

    func saveDeck(update: Bool) {
        guard let deck = deck, let cards = cards, cards.isValidDeck() else { return }
		
		if update {
			RealmHelper.update(deck: deck, with: cards)
		} else {
			RealmHelper.add(deck: deck, with: cards)
		}
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: Events.reload_decks),
                                        object: deck)
        self._delegate?.deckSaveSaved()
        
    }
}
