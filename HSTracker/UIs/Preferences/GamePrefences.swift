//
//  GamePrefences.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 29/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Preferences

class GamePreferences: NSViewController, PreferencePane {
    var preferencePaneIdentifier = Preferences.PaneIdentifier.game
    
    var preferencePaneTitle = NSLocalizedString("Game", comment: "")
    
    var toolbarItemIcon = NSImage(named: "game")!

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
            alert.messageText = NSLocalizedString("Can't find Hearthstone, please select Hearthstone.app", comment: "")
            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
            alert.runModal()
        }

        if let locale = Settings.hsTrackerLanguage,
            let index = Array(Language.HSTracker.allCases).firstIndex(of: locale) {
            hstrackerLanguage.selectItem(at: index)
        }
        if let locale = Settings.hearthstoneLanguage,
            let index = Array(Language.Hearthstone.allCases).firstIndex(of: locale) {
            hearthstoneLanguage.selectItem(at: index)
        }

        autoArchiveArenaDeck.state = Settings.autoArchiveArenaDeck ? .on : .off
        autoSelectDecks.state = Settings.autoDeckDetection ? .on : .off
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

        if openDialog.runModal() == NSApplication.ModalResponse.OK {
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
            Settings.autoArchiveArenaDeck = autoArchiveArenaDeck.state == .on
        } else if sender == autoSelectDecks {
            Settings.autoDeckDetection = autoSelectDecks.state == .on
        }
    }
}

// MARK: - NSComboBoxDataSource / NSComboBoxDelegatemethods
extension GamePreferences: NSComboBoxDataSource, NSComboBoxDelegate {
    func numberOfItems(in aComboBox: NSComboBox) -> Int {
        if aComboBox == hstrackerLanguage {
            return Array(Language.HSTracker.allCases).count
        } else if aComboBox == hearthstoneLanguage {
            return Array(Language.Hearthstone.allCases).count
        }

        return 0
    }

    func comboBox(_ aComboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        if aComboBox == hstrackerLanguage && Array(Language.HSTracker.allCases).count > index {
            return Array(Language.HSTracker.allCases)[index].localizedString
        } else if aComboBox == hearthstoneLanguage && Array(Language.Hearthstone.allCases).count > index {
            return Array(Language.Hearthstone.allCases)[index].localizedString
        }

        return ""
    }

    func comboBoxSelectionDidChange(_ notification: Notification) {
        if let sender = notification.object as? NSComboBox {
            if sender == hearthstoneLanguage
                && Array(Language.Hearthstone.allCases).count > sender.indexOfSelectedItem {
                let index = hearthstoneLanguage!.indexOfSelectedItem
                let hearthstone = Array(Language.Hearthstone.allCases)[index]
                if Settings.hearthstoneLanguage != hearthstone {
                    Settings.hearthstoneLanguage = hearthstone
                }
            } else if sender == hstrackerLanguage
                && Array(Language.HSTracker.allCases).count > sender.indexOfSelectedItem {
                let index = sender.indexOfSelectedItem
                let hstracker = Array(Language.HSTracker.allCases)[index]
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
extension Preferences.PaneIdentifier {
    static let game = Self("game")
}
