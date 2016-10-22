//
//  NewDeck.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

protocol NewDeckDelegate {
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
    @IBOutlet weak var fromHearthstats: NSButton!
    @IBOutlet weak var loader: NSProgressIndicator!

    var delegate: NewDeckDelegate?
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
            fromTheWeb: [urlDeck],
            fromHearthstats: []
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
        } else if fromHearthstats.state == NSOnState {
            do {
                loader.startAnimation(self)
                try HearthstatsAPI.loadDecks(force: false) { (success, newDecks) in
                    self.loader.stopAnimation(self)
                    self.delegate?.refreshDecks()
                    self.window?.sheetParent?.endSheet(self.window!, returnCode: NSModalResponseOK)
                }
            } catch HearthstatsError.notLogged {
                print("not logged")
                self.loader.stopAnimation(self)
            } catch {
                print("??? logged")
                self.loader.stopAnimation(self)
            }
        }
    }

    @IBAction func openDeck(_ sender: AnyObject) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["txt"]

        panel.beginSheetModal(for: self.window!,
                                       completionHandler: { (returnCode) in
                                        if returnCode == NSFileHandlingPanelOKButton {
                                            for filename in panel.urls {
                                                let importer = FileImporter()
                                                if let deck = importer.fileImport(url: filename) {
                                                    self._addDeck(deck)
                                                } else {
                                                    // TODO show error
                                                }
                                            }
                                        }
        })
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
                let alert = NSAlert()
                alert.alertStyle = .informational
                // swiftlint:disable line_length
                alert.messageText = NSLocalizedString("Do you want to add this deck on Hearthstats ?", comment: "")
                alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
                alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
                alert.beginSheetModal(for: self.window!,
                                               completionHandler: { (returnCode) in
                                                if returnCode == NSAlertFirstButtonReturn {
                                                    do {
                                                        try HearthstatsAPI.post(deck: deck) {_ in}
                                                        self.window?.sheetParent?.endSheet(self.window!, returnCode: NSModalResponseOK)
                                                    } catch {
                                                        // TODO alert
                                                        print("error")
                                                    }
                                                }
                })
                // swiftlint:enable line_length
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
        } else if fromHearthstats.state == NSOnState {
            enabled = true
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
