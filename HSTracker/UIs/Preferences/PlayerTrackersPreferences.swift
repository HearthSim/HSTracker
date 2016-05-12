//
//  TrackersPreferences.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 29/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import MASPreferences

class PlayerTrackersPreferences: NSViewController, MASPreferencesViewController {

    @IBOutlet weak var showPlayerTracker: NSButton!
    @IBOutlet weak var showPlayerCardCount: NSButton!
    @IBOutlet weak var showPlayerDrawChance: NSButton!
    @IBOutlet weak var showPlayerGet: NSButton!
    @IBOutlet weak var showCthunCounter: NSButton!
    @IBOutlet weak var showSpellCounter: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        let settings = Settings.instance
        showPlayerTracker.state = settings.showPlayerTracker ? NSOnState : NSOffState
        showPlayerCardCount.state = settings.showPlayerCardCount ? NSOnState : NSOffState
        showPlayerDrawChance.state = settings.showPlayerDrawChance ? NSOnState : NSOffState
        showPlayerGet.state = settings.showPlayerGet ? NSOnState : NSOffState
        showCthunCounter.state = settings.showPlayerCthun ? NSOnState : NSOffState
        showSpellCounter.state = settings.showPlayerYogg ? NSOnState : NSOffState
    }

    @IBAction func checkboxClicked(sender: NSButton) {
        let settings = Settings.instance

        if sender == showPlayerTracker {
            settings.showPlayerTracker = showPlayerTracker.state == NSOnState
        } else if sender == showPlayerGet {
            settings.showPlayerGet = showPlayerGet.state == NSOnState
        } else if sender == showPlayerCardCount {
            settings.showPlayerCardCount = showPlayerCardCount.state == NSOnState
        } else if sender == showPlayerDrawChance {
            settings.showPlayerDrawChance = showPlayerDrawChance.state == NSOnState
        } else if sender == showCthunCounter {
            settings.showPlayerCthun = showCthunCounter.state == NSOnState
        } else if sender == showSpellCounter {
            settings.showPlayerYogg = showSpellCounter.state == NSOnState
        }
    }

    // MARK: - MASPreferencesViewController
    override var identifier: String? {
        get {
            return "player_trackers"
        }
        set {
            super.identifier = newValue
        }
    }

    var toolbarItemImage: NSImage! {
        return NSImage(named: NSImageNameAdvanced)
    }

    var toolbarItemLabel: String! {
        return NSLocalizedString("Player tracker", comment: "")
    }
}
