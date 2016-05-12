//
//  GamePrefences.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 29/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import MASPreferences

class GamePreferences: NSViewController, MASPreferencesViewController,
NSComboBoxDataSource, NSComboBoxDelegate, NSOpenSavePanelDelegate {

    @IBOutlet weak var hearthstonePath: NSTextField!
    @IBOutlet weak var decksPath: NSTextField!
    @IBOutlet weak var chooseHearthstonePath: NSButton!
    @IBOutlet weak var chooseDecksPath: NSButton!
    @IBOutlet weak var hstrackerLanguage: NSComboBox!
    @IBOutlet weak var hearthstoneLanguage: NSComboBox!
    @IBOutlet weak var checkImage: NSImageView!

    let hsLanguages = ["deDE", "enUS", "esES", "esMX", "frFR",
                       "itIT", "koKR", "plPL", "ptBR", "ruRU",
                       "zhCN", "zhTW", "jaJP", "thTH"]
    let hearthstoneLanguages = ["de_DE", "en_US", "es_ES", "es_MX", "fr_FR",
                                "it_IT", "ko_KR", "pl_PL", "pt_BR", "ru_RU",
                                "zh_CN", "zh_TW", "ja_JP", "th_TH"]
    let hstrackerLanguages = ["de", "en", "fr", "it", "pt-br", "zh-cn", "es"]

    override func viewDidLoad() {
        super.viewDidLoad()
        let settings = Settings.instance

        if Hearthstone.validatedHearthstonePath() {
            hearthstonePath.stringValue = settings.hearthstoneLogPath
            hearthstonePath.enabled = false
            chooseHearthstonePath.enabled = false
            checkImage.image = ImageCache.asset("check")
        } else {
            checkImage.image = ImageCache.asset("error")

            let alert = NSAlert()
            alert.alertStyle = .CriticalAlertStyle
            // swiftlint:disable line_length
            alert.messageText = NSLocalizedString("Can't find Hearthstone, please select Hearthstone.app", comment: "")
            // swiftlint:enable line_length
            alert.addButtonWithTitle(NSLocalizedString("OK", comment: ""))
            alert.runModal()
        }

        if let deckPath = settings.deckPath {
            decksPath.stringValue = deckPath
        }

        if let locale = settings.hsTrackerLanguage, index = hstrackerLanguages.indexOf(locale) {
            hstrackerLanguage.selectItemAtIndex(index)
        }
        if let locale = settings.hearthstoneLanguage, index = hsLanguages.indexOf(locale) {
            hearthstoneLanguage.selectItemAtIndex(index)
        }
    }

    @IBAction func choosePath(sender: NSButton) {
        let openDialog = NSOpenPanel()

        if sender == chooseHearthstonePath {
            openDialog.delegate = self
            openDialog.canChooseDirectories = false
            openDialog.allowsMultipleSelection = false
            openDialog.allowedFileTypes = ["app"]
            openDialog.nameFieldStringValue = "Hearthstone.app"
            openDialog.title = NSLocalizedString("Please select your Hearthstone app", comment: "")
        } else if sender == chooseDecksPath {
            openDialog.canChooseDirectories = true
            openDialog.allowsMultipleSelection = false
        }

        if openDialog.runModal() == NSModalResponseOK {
            if let url = openDialog.URLs.first {
                let settings = Settings.instance
                if sender == chooseHearthstonePath {
                    if let path = url.path {
                        hearthstonePath.stringValue = path.replace("/Hearthstone.app", with: "")
                        checkImage.image = ImageCache.asset("check")
                        settings.hearthstoneLogPath = hearthstonePath.stringValue
                    }
                } else if sender == chooseDecksPath {
                    decksPath.stringValue = url.path!
                    settings.deckPath = decksPath.stringValue
                }
            }
        }
    }

    // MARK: - NSComboBoxDataSource methods
    func numberOfItemsInComboBox(aComboBox: NSComboBox) -> Int {
        if aComboBox == hstrackerLanguage {
            return hstrackerLanguages.count
        } else if aComboBox == hearthstoneLanguage {
            return hearthstoneLanguages.count
        }

        return 0
    }

    func comboBox(aComboBox: NSComboBox, objectValueForItemAtIndex index: Int) -> AnyObject {
        var language: String?
        if aComboBox == hstrackerLanguage {
            language = hstrackerLanguages[index]
        } else if aComboBox == hearthstoneLanguage {
            language = hearthstoneLanguages[index]
        }

        if let language = language {
            let locale = NSLocale(localeIdentifier: language)
            return locale.displayNameForKey(NSLocaleIdentifier, value: language)!.capitalizedString
        } else {
            return ""
        }
    }

    func comboBoxSelectionDidChange(notification: NSNotification) {
        if let sender = notification.object as? NSComboBox {
            let settings = Settings.instance
            if sender == hearthstoneLanguage {
                let hearthstone = hsLanguages[hearthstoneLanguage!.indexOfSelectedItem]
                if settings.hearthstoneLanguage != hearthstone {
                    settings.hearthstoneLanguage = hearthstone
                }
            } else if sender == hstrackerLanguage {
                let hstracker = hstrackerLanguages[hstrackerLanguage!.indexOfSelectedItem]
                if settings.hsTrackerLanguage != hstracker {
                    settings.hsTrackerLanguage = hstracker
                }
            }
        }
    }

    // MARK: - MASPreferencesViewController
    override var identifier: String? {
        get {
            return "game"
        }
        set {
            super.identifier = newValue
        }
    }

    var toolbarItemImage: NSImage! {
        return NSImage(named: NSImageNameAdvanced)
    }

    var toolbarItemLabel: String! {
        return NSLocalizedString("Game", comment: "")
    }

    // MARK: - NSOpenSavePanelDelegate
    func panel(sender: AnyObject, shouldEnableURL url: NSURL) -> Bool {
        if url.path!.hasSuffix(".app") {
            return url.lastPathComponent == "Hearthstone.app"
        } else {
            var isDir: ObjCBool = false
            return NSFileManager.defaultManager()
                .fileExistsAtPath(url.path!, isDirectory: &isDir) && isDir
        }
    }
}
