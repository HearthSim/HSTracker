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
        if let hsClass = defaultClass, index = Cards.classes.indexOf(hsClass) {
            classesCombobox.selectItemAtIndex(index)
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

    @IBAction func radioChange(sender: AnyObject) {
        if let buttonSender = sender as? NSButton {
            for (button, control) in radios() {
                if button == buttonSender {
                    button.state = NSOnState
                    control.forEach({ $0.enabled = true })
                } else {
                    button.state = NSOffState
                    control.forEach({ $0.enabled = false })
                }
            }
        }
        checkToEnableSave()
    }

    func setDelegate(delegate: NewDeckDelegate) {
        self.delegate = delegate
    }

    @IBAction func cancelClicked(sender: AnyObject) {
        self.window?.sheetParent?.endSheet(self.window!, returnCode: NSModalResponseCancel)
    }

    @IBAction func okClicked(sender: AnyObject) {
        if hstrackerDeckBuilder.state == NSOnState {
            if classesCombobox.indexOfSelectedItem < 0 {
                return
            }
            delegate?.openDeckBuilder(Cards.classes[classesCombobox.indexOfSelectedItem],
                                      arenaDeck: (arenaDeck.state == NSOnState))
            self.window?.sheetParent?.endSheet(self.window!, returnCode: NSModalResponseOK)
        } else if fromTheWeb.state == NSOnState {
            // TODO add loader
            do {
                loader.startAnimation(self)
                try NetImporter.netImport(urlDeck.stringValue,
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
                try HearthstatsAPI.loadDecks(false) { (success, newDecks) in
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

    @IBAction func openDeck(sender: AnyObject) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["txt"]

        panel.beginSheetModalForWindow(self.window!,
                                       completionHandler: { (returnCode) in
                                        if returnCode == NSFileHandlingPanelOKButton {
                                            for filename in panel.URLs {
                                                let importer = FileImporter()
                                                if let deck = importer.fileImport(filename) {
                                                    self._addDeck(deck)
                                                } else {
                                                    // TODO show error
                                                }
                                            }
                                        }
        })
    }

    private func _addDeck(deck: Deck) {
        self.delegate?.addNewDeck(deck)
        if HearthstatsAPI.isLogged() {
            if Settings.instance.hearthstatsAutoSynchronize {
                do {
                    try HearthstatsAPI.postDeck(deck) {_ in}
                    self.window?.sheetParent?.endSheet(self.window!, returnCode: NSModalResponseOK)
                } catch {}
            } else {
                let alert = NSAlert()
                alert.alertStyle = .Informational
                // swiftlint:disable line_length
                alert.messageText = NSLocalizedString("Do you want to add this deck on Hearthstats ?", comment: "")
                alert.addButtonWithTitle(NSLocalizedString("OK", comment: ""))
                alert.addButtonWithTitle(NSLocalizedString("Cancel", comment: ""))
                alert.beginSheetModalForWindow(self.window!,
                                               completionHandler: { (returnCode) in
                                                if returnCode == NSAlertFirstButtonReturn {
                                                    do {
                                                        try HearthstatsAPI.postDeck(deck) {_ in}
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
            okButton.enabled = enabled
        }
    }

    override func controlTextDidChange(obj: NSNotification) {
        checkToEnableSave()
    }
}

// MARK: - NSComboBoxDelegate
extension NewDeck: NSComboBoxDelegate {
    func comboBoxSelectionDidChange(notification: NSNotification) {
        checkToEnableSave()
    }

    func comboBox(aComboBox: NSComboBox, completedString string: String) -> String? {
        for (idx, hsClass) in Cards.classes.enumerate() {
            if NSLocalizedString(hsClass.rawValue.lowercaseString, comment: "")
                .commonPrefixWithString(string, options: .CaseInsensitiveSearch)
                .length == string.length {
                dispatch_async(dispatch_get_main_queue(), {
                    self.classesCombobox.selectItemAtIndex(idx)
                })
                checkToEnableSave()
                return NSLocalizedString(hsClass.rawValue.lowercaseString, comment: "")
            }
        }
        return string
    }
}

// MARK: - NSComboBoxDataSource
extension NewDeck: NSComboBoxDataSource {
    func numberOfItemsInComboBox(aComboBox: NSComboBox) -> Int {
        return Cards.classes.count
    }

    func comboBox(aComboBox: NSComboBox, objectValueForItemAtIndex index: Int) -> AnyObject? {
        return NSLocalizedString(Cards.classes[index].rawValue.lowercaseString, comment: "")
    }
}
