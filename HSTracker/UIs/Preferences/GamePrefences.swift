//
//  GamePrefences.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 29/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import MASPreferences

class GamePreferences : NSViewController, MASPreferencesViewController {

    @IBOutlet weak var hearthstonePath: NSTextField!
    @IBOutlet weak var decksPath: NSTextField!
    @IBOutlet weak var chooseHearthstonePath: NSButton!
    @IBOutlet weak var chooseDecksPath: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        let settings = Settings.instance
        hearthstonePath.stringValue = settings.hearthstoneLogPath

        if let deckPath = settings.deckPath {
            decksPath.stringValue = deckPath
        }
    }

    @IBAction func choosePath(sender: NSButton) {
        let openDialog = NSOpenPanel()
        openDialog.canChooseDirectories = true
        openDialog.allowsMultipleSelection = false
        if openDialog.runModal() == NSModalResponseOK {
            if let url = openDialog.URLs.first {
                let settings = Settings.instance
                if sender == chooseHearthstonePath {
                    hearthstonePath.stringValue = url.path! + "/Logs"
                    settings.hearthstoneLogPath = hearthstonePath.stringValue
                }
                else if sender == chooseDecksPath {
                    decksPath.stringValue = url.path!
                    settings.deckPath = decksPath.stringValue
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
}