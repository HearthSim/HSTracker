//
//  TrackersPreferences.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 29/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import MASPreferences

class OpponentTrackersPreferences: NSViewController {

    @IBOutlet weak var showOpponentTracker: NSButton!
    @IBOutlet weak var showCardHuds: NSButton!
    @IBOutlet weak var clearTrackersOnGameEnd: NSButton!
    @IBOutlet weak var showOpponentCardCount: NSButton!
    @IBOutlet weak var showOpponentDrawChance: NSButton!
    @IBOutlet weak var showCthunCounter: NSButton!
    @IBOutlet weak var showSpellCounter: NSButton!
    @IBOutlet weak var includeCreated: NSButton!
    @IBOutlet weak var showDeathrattleCounter: NSButton!
    @IBOutlet weak var showPlayerClass: NSButton!
    @IBOutlet weak var showBoardDamage: NSButton!
    @IBOutlet weak var showGraveyard: NSButton!
    @IBOutlet weak var showGraveyardDetails: NSButton!
    @IBOutlet weak var showJadeCounter: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        showOpponentTracker.state = Settings.showOpponentTracker ? NSOnState : NSOffState
        showCardHuds.state = Settings.showCardHuds ? NSOnState : NSOffState
        clearTrackersOnGameEnd.state = Settings.clearTrackersOnGameEnd ? NSOnState : NSOffState
        showOpponentCardCount.state = Settings.showOpponentCardCount ? NSOnState : NSOffState
        showOpponentDrawChance.state = Settings.showOpponentDrawChance ? NSOnState : NSOffState
        showCthunCounter.state = Settings.showOpponentCthun ? NSOnState : NSOffState
        showSpellCounter.state = Settings.showOpponentSpell ? NSOnState : NSOffState
        includeCreated.state = Settings.showOpponentCreated ? NSOnState : NSOffState
        showDeathrattleCounter.state = Settings.showOpponentDeathrattle ? NSOnState : NSOffState
        showPlayerClass.state = Settings.showOpponentClassInTracker ? NSOnState : NSOffState
        showBoardDamage.state = Settings.opponentBoardDamage ? NSOnState : NSOffState
        showGraveyard.state = Settings.showOpponentGraveyard ? NSOnState : NSOffState
        showGraveyardDetails.state = Settings.showOpponentGraveyardDetails ? NSOnState : NSOffState
        showGraveyardDetails.isEnabled = showGraveyard.state == NSOnState
        showJadeCounter.state = Settings.showOpponentJadeCounter ? NSOnState : NSOffState
    }

    @IBAction func checkboxClicked(_ sender: NSButton) {
        if sender == showOpponentTracker {
            Settings.showOpponentTracker = showOpponentTracker.state == NSOnState
        } else if sender == showCardHuds {
            Settings.showCardHuds = showCardHuds.state == NSOnState
        } else if sender == clearTrackersOnGameEnd {
            Settings.clearTrackersOnGameEnd = clearTrackersOnGameEnd.state == NSOnState
        } else if sender == showOpponentCardCount {
            Settings.showOpponentCardCount = showOpponentCardCount.state == NSOnState
        } else if sender == showOpponentDrawChance {
            Settings.showOpponentDrawChance = showOpponentDrawChance.state == NSOnState
        } else if sender == showCthunCounter {
            Settings.showOpponentCthun = showCthunCounter.state == NSOnState
        } else if sender == showSpellCounter {
            Settings.showOpponentSpell = showSpellCounter.state == NSOnState
        } else if sender == includeCreated {
            Settings.showOpponentCreated = includeCreated.state == NSOnState
        } else if sender == showDeathrattleCounter {
            Settings.showOpponentDeathrattle = showDeathrattleCounter.state == NSOnState
        } else if sender == showPlayerClass {
            Settings.showOpponentClassInTracker = showPlayerClass.state == NSOnState
        } else if sender == showBoardDamage {
            Settings.opponentBoardDamage = showBoardDamage.state == NSOnState
        } else if sender == showGraveyard {
            Settings.showOpponentGraveyard = showGraveyard.state == NSOnState
            if showGraveyard.state == NSOnState {
                showGraveyardDetails.isEnabled = true
            } else {
                showGraveyardDetails.isEnabled = false
            }
        } else if sender == showGraveyardDetails {
            Settings.showOpponentGraveyardDetails = showGraveyardDetails.state == NSOnState
        } else if sender == showJadeCounter {
            Settings.showOpponentJadeCounter = showJadeCounter.state == NSOnState
        }
    }
}

// MARK: - MASPreferencesViewController
extension OpponentTrackersPreferences: MASPreferencesViewController {
    override var identifier: String? {
        get {
            return "opponent_trackers"
        }
        set {
            super.identifier = newValue
        }
    }

    var toolbarItemImage: NSImage? {
        return NSImage(named: NSImageNameAdvanced)
    }

    var toolbarItemLabel: String? {
        return NSLocalizedString("Opponent tracker", comment: "")
    }
}
