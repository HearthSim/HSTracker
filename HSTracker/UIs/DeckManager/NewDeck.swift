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
    @IBOutlet weak var classesPopUpMenu: NSPopUpButton!
    @IBOutlet weak var urlDeck: NSTextField!
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
            fromTheWeb: [urlDeck]
        ]
    }

    @IBAction func radioChange(_ sender: AnyObject) {
        if let buttonSender = sender as? NSButton {
            for (button, control) in radios() {
                if button == buttonSender {
                    button.state = NSOnState
                    control.forEach({ $0.isEnabled = true })
                } else {
                    button.state = NSOffState
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
        self.window?.sheetParent?.endSheet(self.window!, returnCode: NSModalResponseCancel)
    }

    @IBAction func okClicked(_ sender: AnyObject) {
        if hstrackerDeckBuilder.state == NSOnState {
            if classesPopUpMenu.indexOfSelectedItem < 0 {
                return
            }
            delegate?.openDeckBuilder(playerClass:
                Cards.classes[classesPopUpMenu.indexOfSelectedItem],
                                      arenaDeck: (arenaDeck.state == NSOnState))
            self.window?.sheetParent?.endSheet(self.window!, returnCode: NSModalResponseOK)
        } else if fromTheWeb.state == NSOnState {
            // TODO add loader
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
        } else if fromAFile.state == NSOnState {
            // add here to remember this case exists
        }
    }

    @IBAction func openDeck(_ sender: AnyObject) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["txt"]

        panel.beginSheetModal(for: self.window!) { (returnCode) in
            if returnCode == NSFileHandlingPanelOKButton {
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

        self.window?.sheetParent?.endSheet(self.window!, returnCode: NSModalResponseOK)
    }

    func checkToEnableSave() {
        okButton.isEnabled =
            hstrackerDeckBuilder.state == NSOnState
        || fromTheWeb.state == NSOnState && !urlDeck.stringValue.isEmpty
        // notice that there's no statement needed to disable OK "fromAFile.state != NSOnState"
    }

    override func controlTextDidChange(_ notification: Notification) {
        checkToEnableSave()
    }
}
