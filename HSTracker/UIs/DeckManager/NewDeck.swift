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
    func openDeckBuilder(playerClass: String, arenaDeck: Bool)
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

    var delegate: NewDeckDelegate?

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
            delegate?.openDeckBuilder(classes()[classesCombobox.indexOfSelectedItem],
                                      arenaDeck: (arenaDeck.state == NSOnState))
            self.window?.sheetParent?.endSheet(self.window!, returnCode: NSModalResponseOK)
        } else if fromTheWeb.state == NSOnState {
            // TODO add loader
            do {
                try NetImporter.netImport(urlDeck.stringValue,
                                          completion: { (deck) -> Void in
                    if let deck = deck {
                        self._addDeck(deck)
                    } else {
                        // TODO show error
                    }
                })
            } catch {
                // TODO show error
            }
        } else if fromAFile.state == NSOnState {
            // add here to remember this case exists
        } else if fromHearthstats.state == NSOnState {
            do {
                try HearthstatsAPI.loadDecks(false) { (success, newDecks) in
                    self.delegate?.refreshDecks()
                    self.window?.sheetParent?.endSheet(self.window!, returnCode: NSModalResponseOK)
                }
            } catch HearthstatsError.NotLogged {
                print("not logged")
            } catch {
                print("??? logged")
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
                                                importer.fileImport(filename) { (deck) in
                                                    if let deck = deck {
                                                        self._addDeck(deck)
                                                    } else {
                                                        // TODO show error
                                                    }
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
                alert.alertStyle = .InformationalAlertStyle
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

    func classes() -> [String] {
        return ["druid", "hunter", "mage", "paladin", "priest",
            "rogue", "shaman", "warlock", "warrior"]
            .sort { NSLocalizedString($0, comment: "") < NSLocalizedString($1, comment: "") }
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
}

// MARK: - NSComboBoxDataSource
extension NewDeck: NSComboBoxDataSource {
    func numberOfItemsInComboBox(aComboBox: NSComboBox) -> Int {
        return classes().count
    }

    func comboBox(aComboBox: NSComboBox, objectValueForItemAtIndex index: Int) -> AnyObject {
        return NSLocalizedString(classes()[index], comment: "")
    }
}
