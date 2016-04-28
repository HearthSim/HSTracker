//
//  TrackersPreferences.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 29/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import MASPreferences

class OpponentTrackersPreferences : NSViewController, MASPreferencesViewController {

    @IBOutlet weak var showOpponentTracker: NSButton!
    @IBOutlet weak var showCardHuds: NSButton!
    @IBOutlet weak var clearTrackersOnGameEnd: NSButton!
    @IBOutlet weak var showOpponentCardCount: NSButton!
    @IBOutlet weak var showOpponentDrawChance: NSButton!
    @IBOutlet weak var showCthunCounter: NSButton!
    @IBOutlet weak var showSpellCounter: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let settings = Settings.instance
        showOpponentTracker.state = settings.showOpponentTracker ? NSOnState : NSOffState
        showCardHuds.state = settings.showCardHuds ? NSOnState : NSOffState
        clearTrackersOnGameEnd.state = settings.clearTrackersOnGameEnd ? NSOnState : NSOffState
        showOpponentCardCount.state = settings.showOpponentCardCount ? NSOnState : NSOffState
        showOpponentDrawChance.state = settings.showOpponentDrawChance ? NSOnState : NSOffState
        showCthunCounter.state = settings.showOpponentCthun ? NSOnState : NSOffState
        showSpellCounter.state = settings.showOpponentYogg ? NSOnState : NSOffState
    }

    @IBAction func checkboxClicked(sender: NSButton) {
        let settings = Settings.instance
        
        if sender == showOpponentTracker {
            settings.showOpponentTracker = showOpponentTracker.state == NSOnState
        }
        else if sender == showCardHuds {
            settings.showCardHuds = showCardHuds.state == NSOnState
        }
        else if sender == clearTrackersOnGameEnd {
            settings.clearTrackersOnGameEnd = clearTrackersOnGameEnd.state == NSOnState
        }
        else if sender == showOpponentCardCount {
            settings.showOpponentCardCount = showOpponentCardCount.state == NSOnState
        }
        else if sender == showOpponentDrawChance {
            settings.showOpponentDrawChance = showOpponentDrawChance.state == NSOnState
        }
        else if sender == showCthunCounter {
            settings.showOpponentCthun = showCthunCounter.state == NSOnState
        }
        else if sender == showSpellCounter {
            settings.showOpponentYogg = showSpellCounter.state == NSOnState
        }
    }

    // MARK: - MASPreferencesViewController
    override var identifier: String? {
        get {
            return "opponent_trackers"
        }
        set {
            super.identifier = newValue
        }
    }

    var toolbarItemImage: NSImage! {
        return NSImage(named: NSImageNameAdvanced)
    }

    var toolbarItemLabel: String! {
        return NSLocalizedString("Opponent tracker", comment: "")
    }
}