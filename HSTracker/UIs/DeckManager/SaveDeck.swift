//
//  SaveDeck.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 24/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger
import RealmSwift

protocol SaveDeckDelegate: class {
    func deckSaveSaved()
    func deckSaveCanceled()
}

class SaveDeck: NSWindowController {

    @IBOutlet weak var deckName: NSTextField!
    @IBOutlet weak var version: NSComboBox!
    @IBOutlet weak var saveHearthstats: NSButton!

    var deck: Deck?
    var cards: [Card]?
    var exists = false
    weak private var _delegate: SaveDeckDelegate?
    var versions = ["1.0"]

    func setDelegate(_ delegate: SaveDeckDelegate) {
        _delegate = delegate
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        saveHearthstats.isEnabled = HearthstatsAPI.isLogged()

        deckName.stringValue = deck!.name 

        do {
            let realm = try Realm()

            if let _ = realm.objects(Deck.self).filter("deckId = '\(deck!.deckId)'").first {
                exists = true
            }
        } catch {
            Log.error?.message("Can not fetch deck")
        }

        if exists {
            let version = deck!.version
            let nextMinorVersion = "\(Double(version)! + 0.1)"
            let nextMajorVersion = "\(round(Double(version)! + 1))"
            versions = [version, nextMinorVersion, nextMajorVersion]
        } else {
            version.selectItem(at: 0)
        }
        version.isEnabled = exists
        version.reloadData()
    }

    // MARK: - Actions
    @IBAction func save(_ sender: AnyObject) {
        guard let deck = deck, let cards = cards, cards.isValidDeck() else { return }

        let currentVersion = deck.version
        let selectedVersion = version.indexOfSelectedItem < 0
            ? versions[0] : versions[version.indexOfSelectedItem]

        let isNewVersion = currentVersion != selectedVersion

        do {
            let realm = try Realm()

            try realm.write {
                deck.version = selectedVersion
                deck.name = deckName.stringValue
            }
        } catch {
            Log.error?.message("can not save deck : \(error)")
        }

        if HearthstatsAPI.isLogged() && saveHearthstats.state == NSOnState {
            if !exists || deck.hearthstatsId.value == nil {
                do {
                    try HearthstatsAPI.post(deck: deck, callback: { (success) in
                        if success {
                            self.saveDeck(update: false)
                        }
                    })
                } catch {
                    // TODO alert error
                }
            } else if isNewVersion {
                do {
                    try HearthstatsAPI.post(deckVersion: deck, callback: { (success) in
                        if success {
                            self.saveDeck(update: true)
                        }
                    })
                } catch {
                    // TODO alert error
                }
            } else {
                do {
                    try HearthstatsAPI.update(deck: deck, callback: { (success) in
                        if success {
                            self.saveDeck(update: true)
                        }
                    })
                } catch {
                    // TODO alert error
                }
            }
        } else {
            if exists {
                self.saveDeck(update: true)
            } else {
                self.saveDeck(update: false)
            }
        }
    }

    @IBAction func cancel(_ sender: AnyObject) {
        self._delegate?.deckSaveCanceled()
    }

    func saveDeck(update: Bool) {
        guard let deck = deck, let cards = cards, cards.isValidDeck() else { return }
        do {
            let realm = try Realm()
            try realm.write {
                if update {
                    realm.add(deck, update: true)
                } else {
                    realm.add(deck)
                }
                deck.cards.removeAll()
                for card in cards {
                    deck.add(card: card)
                }
            }
            NotificationCenter.default.post(name: Notification.Name(rawValue: "reload_decks"),
                                            object: deck)
            self._delegate?.deckSaveSaved()
        } catch {
            Log.error?.message("Can not save deck : \(error)")
        }
    }
}

// MARK: - NSComboboxDelegate/Datasource
extension SaveDeck: NSComboBoxDelegate, NSComboBoxDataSource {
    func numberOfItems(in aComboBox: NSComboBox) -> Int {
        return versions.count
    }

    func comboBox(_ aComboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        return versions[index]
    }
}
