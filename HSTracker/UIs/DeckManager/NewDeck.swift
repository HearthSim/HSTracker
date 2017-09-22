//
//  NewDeck.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger
import RealmSwift
import AppKit

protocol NewDeckDelegate: class {
    func addNewDeck(deck: Deck)
    func openDeckBuilder(playerClass: CardClass, arenaDeck: Bool)
    func refreshDecks()
}

class NewDeck: NSWindowController {
    
    @IBOutlet weak var hstrackerDeckBuilder: NSButton!
    @IBOutlet weak var fromAFile: NSButton!
    @IBOutlet weak var fromTheWeb: NSButton!
    @IBOutlet weak var fromDeckString: NSButton!
    @IBOutlet weak var classesPopUpMenu: NSPopUpButton!
    @IBOutlet weak var urlDeck: NSTextField!
    @IBOutlet weak var deckString: NSTextField!
    @IBOutlet weak var chooseFile: NSButton!
    @IBOutlet weak var okButton: NSButton!
    @IBOutlet weak var arenaDeck: NSButton!
    @IBOutlet weak var loader: NSProgressIndicator!

    weak var delegate: NewDeckDelegate?
    var defaultClass: CardClass?

    override func windowDidLoad() {
        super.windowDidLoad()
        
        classesPopUpMenu.addItems(withTitles: Cards.classes.map {
            NSLocalizedString($0.rawValue.lowercased(), comment: "")
        })
        checkToEnableSave()
    }

    func radios() -> [NSButton: [NSControl]] {
        return [
            hstrackerDeckBuilder: [classesPopUpMenu, arenaDeck],
            fromAFile: [chooseFile],
            fromTheWeb: [urlDeck],
            fromDeckString: [deckString]
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
        } else if fromTheWeb.state == .on {
            do {
                loader.startAnimation(self)
                try NetImporter.netImport(url: urlDeck.stringValue,
                                          completion: { (deck, message) -> Void in
                                            self.loader.stopAnimation(self)
                                            if let deck = deck {
                                                self._addDeck(deck)
                                                if let message = message {
                                                    NSAlert.show(style: .informational,
                                                                 message: message)
                                                }
                                            } else {
                                                let msg = NSLocalizedString("Failed to import deck"
                                                    + " from \n", comment: "")
                                                    + self.urlDeck.stringValue
                                                NSAlert.show(style: .critical,
                                                             message: msg)
                                            }
                })
            } catch {
                self.loader.stopAnimation(self)
                let msg = NSLocalizedString("Failed to import deck from \n", comment: "")
                    + self.urlDeck.stringValue
                NSAlert.show(style: .critical,
                             message: msg)
            }
        } else if fromAFile.state == .on {
            // add here to remember this case exists
        } else if fromDeckString.state == .on {
            let string = deckString.stringValue

            let deck = Deck()
            let cards: [Card]?
            if let serializedDeck = DeckSerializer.deserialize(input: string) {
                deck.playerClass = serializedDeck.playerClass
                deck.name = serializedDeck.name
                cards = serializedDeck.cards
            } else if let (cardClass, _cards) = DeckSerializer.deserializeDeckString(deckString: string) {
                deck.playerClass = cardClass
                deck.name = "Imported deck"
                cards = _cards
            } else {
                let msg = NSLocalizedString("Failed to import deck from \n", comment: "")
                    + string
                NSAlert.show(style: .critical,
                             message: msg)
                return
            }

            if let _cards = cards {
                RealmHelper.add(deck: deck, with: _cards)
                self._addDeck(deck)
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
            if returnCode.rawValue == NSFileHandlingPanelOKButton {
                for filename in panel.urls {
                    let importer = FileImporter()
                    if let (deck, cards) = importer.fileImport(url: filename), cards.isValidDeck() {
                        for card in cards {
                            deck.add(card: card)
                        }
                        RealmHelper.add(deck: deck)
                        self._addDeck(deck)
                    } else {
                        // TODO show error
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
        || fromTheWeb.state == .on && !urlDeck.stringValue.isEmpty
        || fromDeckString.state == .on && !deckString.stringValue.isEmpty
        // notice that there's no statement needed to disable OK "fromAFile.state != .on"
    }

    override func controlTextDidChange(_ notification: Notification) {
        checkToEnableSave()
    }
}
