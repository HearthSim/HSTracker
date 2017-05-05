//
//  GamePrefences.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 29/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import MASPreferences

class GamePreferences: NSViewController {

    @IBOutlet weak var hearthstonePath: NSTextField!
    @IBOutlet weak var decksPath: NSTextField!
    @IBOutlet weak var chooseHearthstonePath: NSButton!
    @IBOutlet weak var hstrackerLanguage: NSComboBox!
    @IBOutlet weak var hearthstoneLanguage: NSComboBox!
    @IBOutlet weak var checkImage: NSImageView!
    @IBOutlet weak var autoArchiveArenaDeck: NSButton!
    @IBOutlet weak var autoSelectDecks: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        if CoreManager.validatedHearthstonePath() {
            hearthstonePath.stringValue = Settings.hearthstonePath
            hearthstonePath.isEnabled = false
            chooseHearthstonePath.isEnabled = false
            checkImage.image = NSImage(named: "check")
        } else {
            checkImage.image = NSImage(named: "error")

            let alert = NSAlert()
            alert.alertStyle = .critical
            // swiftlint:disable line_length
            alert.messageText = NSLocalizedString("Can't find Hearthstone, please select Hearthstone.app", comment: "")
            // swiftlint:enable line_length
            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
            alert.runModal()
        }

        if let locale = Settings.hsTrackerLanguage,
            let index = Array(Language.HSTracker.cases()).index(of: locale) {
            hstrackerLanguage.selectItem(at: index)
        }
        if let locale = Settings.hearthstoneLanguage,
            let index = Array(Language.Hearthstone.cases()).index(of: locale) {
            hearthstoneLanguage.selectItem(at: index)
        }

        autoArchiveArenaDeck.state = Settings.autoArchiveArenaDeck ? NSOnState : NSOffState
        autoSelectDecks.state = Settings.autoDeckDetection ? NSOnState : NSOffState
    }

    @IBAction func choosePath(_ sender: NSButton) {
        let openDialog = NSOpenPanel()

        if sender == chooseHearthstonePath {
            openDialog.delegate = self
            openDialog.canChooseDirectories = false
            openDialog.allowsMultipleSelection = false
            openDialog.allowedFileTypes = ["app"]
            openDialog.nameFieldStringValue = "Hearthstone.app"
            openDialog.title = NSLocalizedString("Please select your Hearthstone app", comment: "")
        }

        if openDialog.runModal() == NSModalResponseOK {
            if let url = openDialog.urls.first {
                if sender == chooseHearthstonePath {
                    let path = url.path
                    hearthstonePath.stringValue = path.replace("/Hearthstone.app", with: "")
                    checkImage.image = NSImage(named: "check")
                    Settings.hearthstonePath = hearthstonePath.stringValue
                }
            }
        }
    }

    @IBAction func checkboxClicked(_ sender: NSButton) {
        if sender == autoArchiveArenaDeck {
            Settings.autoArchiveArenaDeck = autoArchiveArenaDeck.state == NSOnState
        } else if sender == autoSelectDecks {
            Settings.autoDeckDetection = autoSelectDecks.state == NSOnState
        }
    }
}

// MARK: - NSComboBoxDataSource / NSComboBoxDelegatemethods
extension GamePreferences: NSComboBoxDataSource, NSComboBoxDelegate {
    func numberOfItems(in aComboBox: NSComboBox) -> Int {
        if aComboBox == hstrackerLanguage {
            return Array(Language.HSTracker.cases()).count
        } else if aComboBox == hearthstoneLanguage {
            return Array(Language.Hearthstone.cases()).count
        }

        return 0
    }

    func comboBox(_ aComboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        if aComboBox == hstrackerLanguage && Array(Language.HSTracker.cases()).count > index {
            return Array(Language.HSTracker.cases())[index].localizedString
        } else if aComboBox == hearthstoneLanguage && Array(Language.Hearthstone.cases()).count > index {
            return Array(Language.Hearthstone.cases())[index].localizedString
        }

        return ""
    }

    func comboBoxSelectionDidChange(_ notification: Notification) {
        if let sender = notification.object as? NSComboBox {
            if sender == hearthstoneLanguage
                && Array(Language.Hearthstone.cases()).count > sender.indexOfSelectedItem {
                let index = hearthstoneLanguage!.indexOfSelectedItem
                let hearthstone = Array(Language.Hearthstone.cases())[index]
                if Settings.hearthstoneLanguage != hearthstone {
                    Settings.hearthstoneLanguage = hearthstone
                }
            } else if sender == hstrackerLanguage
                && Array(Language.HSTracker.cases()).count > sender.indexOfSelectedItem {
                let index = sender.indexOfSelectedItem
                let hstracker = Array(Language.HSTracker.cases())[index]
                if Settings.hsTrackerLanguage != hstracker {
                    Settings.hsTrackerLanguage = hstracker
                }
            }
        }
    }
}
    // MARK: - NSOpenSavePanelDelegate
extension GamePreferences: NSOpenSavePanelDelegate {
    func panel(_ sender: Any, shouldEnable url: URL) -> Bool {
        if url.path.hasSuffix(".app") {
            return url.lastPathComponent == "Hearthstone.app"
        } else {
            var isDir: ObjCBool = false
            return FileManager.default
                .fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
        }
    }
}

// MARK: - MASPreferencesViewController
extension GamePreferences: MASPreferencesViewController {
    override var identifier: String? {
        get {
            return "game"
        }
        set {
            super.identifier = newValue
        }
    }
    
    var toolbarItemImage: NSImage? {
        return NSImage(named: NSImageNameAdvanced)
    }
    
    var toolbarItemLabel: String? {
        return NSLocalizedString("Game", comment: "")
    }
}
