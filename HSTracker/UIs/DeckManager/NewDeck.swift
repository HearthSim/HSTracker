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

protocol NewDeckDelegate: class {
    func addNewDeck(deck: Deck)
    func openDeckBuilder(playerClass: CardClass, arenaDeck: Bool)
    func refreshDecks()
}

class NewDeck: NSWindowController {

    @IBOutlet weak var hstrackerDeckBuilder: NSButton!
    @IBOutlet weak var fromAFile: NSButton!
    @IBOutlet weak var fromTheWeb: NSButton!
    @IBOutlet weak var classesCombobox: NSComboBox!
    @IBOutlet weak var urlDeck: NSTextField!
    @IBOutlet weak var chooseFile: NSButton!
    @IBOutlet weak var okButton: NSButton!
    @IBOutlet weak var arenaDeck: NSButton!
    @IBOutlet weak var loader: NSProgressIndicator!

    weak var delegate: NewDeckDelegate?
    var defaultClass: CardClass?

    override func windowDidLoad() {
        super.windowDidLoad()
        if let hsClass = defaultClass, let index = Cards.classes.index(of: hsClass) {
            classesCombobox.selectItem(at: index)
        } else {
            classesCombobox.becomeFirstResponder()
        }
    }

    func radios() -> [NSButton: [NSControl]] {
        return [
            hstrackerDeckBuilder: [classesCombobox, arenaDeck],
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
            if classesCombobox.indexOfSelectedItem < 0 {
                return
            }
            delegate?.openDeckBuilder(playerClass:
                Cards.classes[classesCombobox.indexOfSelectedItem],
                                      arenaDeck: (arenaDeck.state == NSOnState))
            self.window?.sheetParent?.endSheet(self.window!, returnCode: NSModalResponseOK)
        } else if fromTheWeb.state == NSOnState {
            // TODO add loader
            do {
                loader.startAnimation(self)
                try NetImporter.netImport(url: urlDeck.stringValue,
                                          completion: { (deck) -> Void in
                                            self.loader.stopAnimation(self)
                                            if let deck = deck {
                                                self._addDeck(deck)
                                            } else {
                                                // show error
                                                let alertDialog: NSAlert = NSAlert()
                                                // swiftlint:disable line_length
                                                alertDialog.messageText = NSLocalizedString("Failed to import deck from \n", comment: "") + self.urlDeck.stringValue
                                                // swiftlint:enable line_length
                                                alertDialog.runModal()
                                            }
                })
            } catch {
                self.loader.stopAnimation(self)
                // show error
                let alertDialog: NSAlert = NSAlert()
                // swiftlint:disable line_length
                alertDialog.messageText = NSLocalizedString("Failed to import deck from \n", comment: "") + self.urlDeck.stringValue
                // swiftlint:enable line_length
                alertDialog.runModal()
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
                        do {
                            let realm = try Realm()
                            try realm.write {
                                realm.add(deck)
                            }

                            for card in cards {
                                deck.add(card: card)
                            }
                        } catch {
                            Log.error?.message("Can not import deck. Error : \(error)")
                        }
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
        if HearthstatsAPI.isLogged() {
            if Settings.instance.hearthstatsAutoSynchronize {
                do {
                    try HearthstatsAPI.post(deck: deck) {_ in}
                    self.window?.sheetParent?.endSheet(self.window!, returnCode: NSModalResponseOK)
                } catch {}
            } else {
                let msg = NSLocalizedString("Do you want to add this deck on Hearthstats ?",
                                            comment: "")
                NSAlert.show(style: .informational, message: msg, window: self.window!) {
                    do {
                        try HearthstatsAPI.post(deck: deck) {_ in}
                        self.window?.sheetParent?.endSheet(self.window!,
                                                           returnCode: NSModalResponseOK)
                    } catch {
                        // TODO alert
                        Log.error?.message("error")
                    }
                }
            }
        } else {
            self.window?.sheetParent?.endSheet(self.window!, returnCode: NSModalResponseOK)
        }
    }

    func checkToEnableSave() {
        var enabled: Bool?
        if hstrackerDeckBuilder.state == NSOnState {
            enabled = classesCombobox.indexOfSelectedItem != -1
        } else if fromTheWeb.state == NSOnState {
            enabled = !urlDeck.stringValue.isEmpty
        } else if fromAFile.state == NSOnState {
            enabled = false
        }

        if let enabled = enabled {
            okButton.isEnabled = enabled
        }
    }

    override func controlTextDidChange(_ obj: Notification) {
        checkToEnableSave()
    }
}

// MARK: - NSComboBoxDelegate
extension NewDeck: NSComboBoxDelegate {
    func comboBoxSelectionDidChange(_ notification: Notification) {
        checkToEnableSave()
    }

    func comboBox(_ aComboBox: NSComboBox, completedString string: String) -> String? {
        for (idx, hsClass) in Cards.classes.enumerated() {
            if NSLocalizedString(hsClass.rawValue.lowercased(), comment: "")
                .commonPrefix(with: string, options: .caseInsensitive)
                .characters.count == string.characters.count {
                DispatchQueue.main.async(execute: {
                    self.classesCombobox.selectItem(at: idx)
                })
                checkToEnableSave()
                return NSLocalizedString(hsClass.rawValue.lowercased(), comment: "")
            }
        }
        return string
    }
}

// MARK: - NSComboBoxDataSource
extension NewDeck: NSComboBoxDataSource {
    func numberOfItems(in aComboBox: NSComboBox) -> Int {
        return Cards.classes.count
    }

    func comboBox(_ aComboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        return NSLocalizedString(Cards.classes[index].rawValue.lowercased(), comment: "")
    }
}
