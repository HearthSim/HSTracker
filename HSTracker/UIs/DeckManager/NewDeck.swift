//
//  NewDeck.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import RealmSwift
import AppKit

protocol NewDeckDelegate: AnyObject {
    func addNewDeck(deck: Deck)
    func openDeckBuilder(playerClass: CardClass, arenaDeck: Bool)
    func refreshDecks()
}

class NewDeck: NSWindowController, NSControlTextEditingDelegate {
    
    @IBOutlet var hstrackerDeckBuilder: NSButton!
    @IBOutlet var fromAFile: NSButton!
    @IBOutlet var fromDeckString: NSButton!
    @IBOutlet var classesPopUpMenu: NSPopUpButton!
    @IBOutlet var chooseFile: NSButton!
    @IBOutlet var okButton: NSButton!
    @IBOutlet var arenaDeck: NSButton!
    @IBOutlet var loader: NSProgressIndicator!

    weak var delegate: NewDeckDelegate?
    var defaultClass: CardClass?

    override func windowDidLoad() {
        super.windowDidLoad()
        
        classesPopUpMenu.addItems(withTitles: Cards.classes.map {
            String.localizedString($0.rawValue.lowercased(), comment: "")
        })
        checkToEnableSave()
    }

    func radios() -> [NSButton: [NSControl]] {
        return [
            hstrackerDeckBuilder: [classesPopUpMenu, arenaDeck],
            fromAFile: [chooseFile],
            fromDeckString: []
        ]
    }

    @IBAction func radioChange(_ sender: AnyObject) {
        if let buttonSender = sender as? NSButton {
            for (button, control) in radios() {
                if button == buttonSender {
                    button.state = .on
                    control.forEach({ $0.isEnabled = true })
                } else {
                    button.state = .off
                    control.forEach({ $0.isEnabled = false })
                }
            }
        }
        checkToEnableSave()
    }

    func setDelegate(_ delegate: NewDeckDelegate) {
        self.delegate = delegate
    }

    @IBAction func cancelClicked(_ sender: AnyObject) {
        self.window?.sheetParent?.endSheet(self.window!, returnCode: NSApplication.ModalResponse.cancel)
    }

    @IBAction func okClicked(_ sender: AnyObject) {
        if hstrackerDeckBuilder.state == .on {
            if classesPopUpMenu.indexOfSelectedItem < 0 {
                return
            }
            delegate?.openDeckBuilder(playerClass:
                Cards.classes[classesPopUpMenu.indexOfSelectedItem],
                                      arenaDeck: (arenaDeck.state == .on))
            self.window?.sheetParent?.endSheet(self.window!, returnCode: NSApplication.ModalResponse.OK)
        } else if fromAFile.state == .on {
            // add here to remember this case exists
        } else if fromDeckString.state == .on {
            if let serializedDeck = ClipboardImporter.clipboardImport() {
                let deck = Deck()
                let cards: [Card]?
                deck.playerClass = serializedDeck.getHero()?.playerClass ?? .invalid
                deck.name = serializedDeck.name
                cards = serializedDeck.cards
                
                if let _cards = cards {
                    RealmHelper.add(deck: deck, with: _cards)
                    self._addDeck(deck)
                }
            } else {
                let msg = String.localizedString("Failed to import deck from the Clipboard", comment: "")
                NSAlert.show(style: .critical,
                             message: msg)
                return
            }
        }
    }

    @IBAction func openDeck(_ sender: AnyObject) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["txt"]

        panel.beginSheetModal(for: self.window!) { (returnCode) in
            if returnCode == NSApplication.ModalResponse.OK {
                for filename in panel.urls {
                    let importer = FileImporter()
                    if let (deck, cards) = importer.fileImport(url: filename), cards.isValidDeck() {
                        RealmHelper.add(deck: deck, with: cards)
                        self._addDeck(deck)
                    } else {
                        let msg = String.localizedString("Failed to import deck from \n", comment: "")
                        + filename.path
                        NSAlert.show(style: .critical,
                                     message: msg)
                        return
                    }
                }
            }
        }
    }

    fileprivate func _addDeck(_ deck: Deck) {
        self.delegate?.addNewDeck(deck: deck)

        self.window?.sheetParent?.endSheet(self.window!, returnCode: NSApplication.ModalResponse.OK)
    }

    func checkToEnableSave() {
        okButton.isEnabled =
            hstrackerDeckBuilder.state == .on
        || fromDeckString.state == .on
        // notice that there's no statement needed to disable OK "fromAFile.state != .on"
    }

    func controlTextDidChange(_ notification: Notification) {
        checkToEnableSave()
    }
}
