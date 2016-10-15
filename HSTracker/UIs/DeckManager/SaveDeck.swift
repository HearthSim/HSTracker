//
//  SaveDeck.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 24/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

protocol SaveDeckDelegate {
    func deckSaveSaved()
    func deckSaveCanceled()
}

class SaveDeck: NSWindowController {

    @IBOutlet weak var deckName: NSTextField!
    @IBOutlet weak var version: NSComboBox!
    @IBOutlet weak var saveHearthstats: NSButton!

    var deck: Deck?
    private var _delegate: SaveDeckDelegate?
    var versions = ["1.0"]

    func setDelegate(_ delegate: SaveDeckDelegate) {
        _delegate = delegate
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        saveHearthstats.isEnabled = HearthstatsAPI.isLogged()

        deckName.stringValue = deck!.name ?? ""

        let exists = (deck!.creationDate != nil)

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
        deck?.name = deckName.stringValue
        let currentVersion = deck?.version
        let selectedVersion = version.indexOfSelectedItem < 0
            ? versions[0] : versions[version.indexOfSelectedItem]
        let exists = (deck!.creationDate != nil)
        let isNewVersion = currentVersion != selectedVersion
        deck?.version = selectedVersion
        if HearthstatsAPI.isLogged() && saveHearthstats.state == NSOnState {
            if !exists || deck!.hearthstatsId == nil {
                do {
                    try HearthstatsAPI.post(deck: deck!, callback: { (success) in
                        if success {
                            Decks.instance.add(deck: self.deck!)
                            self._delegate?.deckSaveSaved()
                        }
                    })
                } catch {
                    // TODO alert error
                }
            } else if isNewVersion {
                do {
                    try HearthstatsAPI.post(deckVersion: deck!, callback: { (success) in
                        if success {
                            Decks.instance.update(deck: self.deck!)
                            self._delegate?.deckSaveSaved()
                        }
                    })
                } catch {
                    // TODO alert error
                }
            } else {
                do {
                    try HearthstatsAPI.update(deck: deck!, callback: { (success) in
                        if success {
                            Decks.instance.update(deck: self.deck!)
                            self._delegate?.deckSaveSaved()
                        }
                    })
                } catch {
                    // TODO alert error
                }
            }
        } else {
            if exists {
                Decks.instance.update(deck: deck!)
            } else {
                Decks.instance.add(deck: deck!)
            }
            self._delegate?.deckSaveSaved()
        }
    }

    @IBAction func cancel(_ sender: AnyObject) {
        self._delegate?.deckSaveCanceled()
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
