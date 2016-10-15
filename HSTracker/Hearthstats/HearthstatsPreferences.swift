//
//  HearthstatsPreferences.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 25/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import MASPreferences

class HearthstatsPreferences: NSViewController {

    @IBOutlet weak var autoSynchronize: NSButton!
    @IBOutlet weak var synchronizeMatches: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        let settings = Settings.instance

        autoSynchronize.state = settings.hearthstatsAutoSynchronize ? NSOnState : NSOffState
        synchronizeMatches.state = settings.hearthstatsSynchronizeMatches ? NSOnState : NSOffState
    }

    @IBAction func checkboxClicked(_ sender: NSButton) {
        let settings = Settings.instance
        if sender == autoSynchronize {
            settings.hearthstatsAutoSynchronize = autoSynchronize.state == NSOnState
        } else if sender == synchronizeMatches {
            settings.hearthstatsSynchronizeMatches = synchronizeMatches.state == NSOnState
        }
    }
}

// MARK: - MASPreferencesViewController
extension HearthstatsPreferences: MASPreferencesViewController {
    override var identifier: String? {
        get {
            return "hearthstats"
        }
        set {
            super.identifier = newValue
        }
    }

    var toolbarItemImage: NSImage? {
        return NSImage(named: "hearthstats_icon")
    }

    var toolbarItemLabel: String? {
        return "Hearthstats"
    }
}
