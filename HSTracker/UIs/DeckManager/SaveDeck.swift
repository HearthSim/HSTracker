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

    func setDelegate(delegate: SaveDeckDelegate) {
        _delegate = delegate
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        saveHearthstats.enabled = HearthstatsAPI.isLogged()

        deckName.stringValue = deck!.name ?? ""

        let exists = (deck!.creationDate != nil)

        if exists {
            let version = deck!.version
            let nextMinorVersion = "\(Double(version)! + 0.1)"
            let nextMajorVersion = "\(round(Double(version)! + 1))"
            versions = [version, nextMinorVersion, nextMajorVersion]
        } else {
            version.selectItemAtIndex(0)
        }
        version.enabled = exists
        version.reloadData()
    }

    // MARK: - Actions
    @IBAction func save(sender: AnyObject) {
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
                    try HearthstatsAPI.postDeck(deck!, { (success) in
                        if success {
                            Decks.instance.add(self.deck!)
                            self._delegate?.deckSaveSaved()
                        }
                    })
                } catch {
                    // TODO alert error
                }
            } else if isNewVersion {
                do {
                    try HearthstatsAPI.postDeckVersion(deck!, { (success) in
                        if success {
                            Decks.instance.update(self.deck!)
                            self._delegate?.deckSaveSaved()
                        }
                    })
                } catch {
                    // TODO alert error
                }
            } else {
                do {
                    try HearthstatsAPI.updateDeck(deck!, { (success) in
                        if success {
                            Decks.instance.update(self.deck!)
                            self._delegate?.deckSaveSaved()
                        }
                    })
                } catch {
                    // TODO alert error
                }
            }
        } else {
            if exists {
                Decks.instance.update(deck!)
            } else {
                Decks.instance.add(deck!)
            }
            self._delegate?.deckSaveSaved()
        }
    }

    @IBAction func cancel(sender: AnyObject) {
        self._delegate?.deckSaveCanceled()
    }

    // MARK: - NSComboboxDelegate/Datasource
    func numberOfItemsInComboBox(aComboBox: NSComboBox) -> Int {
        return versions.count
    }

    func comboBox(aComboBox: NSComboBox, objectValueForItemAtIndex index: Int) -> AnyObject {
        return versions[index]
    }
}
