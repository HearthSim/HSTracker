//
//  TrackersPreferences.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 29/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import MASPreferences

class PlayerTrackersPreferences: NSViewController {

    @IBOutlet weak var showPlayerTracker: NSButton!
    @IBOutlet weak var showPlayerCardCount: NSButton!
    @IBOutlet weak var showPlayerDrawChance: NSButton!
    @IBOutlet weak var showPlayerGet: NSButton!
    @IBOutlet weak var showCthunCounter: NSButton!
    @IBOutlet weak var showSpellCounter: NSButton!
    @IBOutlet weak var showDeathrattleCounter: NSButton!
    @IBOutlet weak var flashOnDraw: NSButton!
    @IBOutlet weak var showRecord: NSButton!
    @IBOutlet weak var inHandColor: NSColorWell!
    @IBOutlet weak var showBoardDamage: NSButton!
    @IBOutlet weak var showDeckName: NSButton!
    @IBOutlet weak var showGraveyard: NSButton!
    @IBOutlet weak var showGraveyardDetails: NSButton!
    @IBOutlet weak var showJadeCounter: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        showPlayerTracker.state = Settings.showPlayerTracker ? NSOnState : NSOffState
        showPlayerCardCount.state = Settings.showPlayerCardCount ? NSOnState : NSOffState
        showPlayerDrawChance.state = Settings.showPlayerDrawChance ? NSOnState : NSOffState
        showPlayerGet.state = Settings.showPlayerGet ? NSOnState : NSOffState
        showCthunCounter.state = Settings.showPlayerCthun ? NSOnState : NSOffState
        showSpellCounter.state = Settings.showPlayerSpell ? NSOnState : NSOffState
        showDeathrattleCounter.state = Settings.showPlayerDeathrattle ? NSOnState : NSOffState
        flashOnDraw.state = Settings.flashOnDraw ? NSOnState : NSOffState
        showRecord.state = Settings.showWinLossRatio ? NSOnState : NSOffState
        inHandColor.color = Settings.playerInHandColor
        showBoardDamage.state = Settings.playerBoardDamage ? NSOnState : NSOffState
        showDeckName.state = Settings.showDeckNameInTracker ? NSOnState : NSOffState
        showGraveyard.state = Settings.showPlayerGraveyard ? NSOnState : NSOffState
        showGraveyardDetails.state = Settings.showPlayerGraveyardDetails ? NSOnState : NSOffState
        showGraveyardDetails.isEnabled = showGraveyard.state == NSOnState
        showJadeCounter.state = Settings.showPlayerJadeCounter ? NSOnState : NSOffState
    }
    
    @IBAction func colorChange(_ sender: NSColorWell) {
        if sender == inHandColor {
            Settings.playerInHandColor = inHandColor.color
        }
    }

    @IBAction func checkboxClicked(_ sender: NSButton) {
        if sender == showPlayerTracker {
            Settings.showPlayerTracker = showPlayerTracker.state == NSOnState
        } else if sender == showPlayerGet {
            Settings.showPlayerGet = showPlayerGet.state == NSOnState
        } else if sender == showPlayerCardCount {
            Settings.showPlayerCardCount = showPlayerCardCount.state == NSOnState
        } else if sender == showPlayerDrawChance {
            Settings.showPlayerDrawChance = showPlayerDrawChance.state == NSOnState
        } else if sender == showCthunCounter {
            Settings.showPlayerCthun = showCthunCounter.state == NSOnState
        } else if sender == showSpellCounter {
            Settings.showPlayerSpell = showSpellCounter.state == NSOnState
        } else if sender == showDeathrattleCounter {
            Settings.showPlayerDeathrattle = showDeathrattleCounter.state == NSOnState
        } else if sender == flashOnDraw {
            Settings.flashOnDraw = flashOnDraw.state == NSOnState
        } else if sender == showRecord {
            Settings.showWinLossRatio = showRecord.state == NSOnState
        } else if sender == showBoardDamage {
            Settings.playerBoardDamage = showBoardDamage.state == NSOnState
        } else if sender == showDeckName {
            Settings.showDeckNameInTracker = showDeckName.state == NSOnState
        } else if sender == showGraveyard {
            Settings.showPlayerGraveyard = showGraveyard.state == NSOnState
            if showGraveyard.state == NSOnState {
                showGraveyardDetails.isEnabled = true
            } else {
                showGraveyardDetails.isEnabled = false
            }
        } else if sender == showGraveyardDetails {
            Settings.showPlayerGraveyardDetails = showGraveyardDetails.state == NSOnState
        } else if sender == showJadeCounter {
            Settings.showPlayerJadeCounter = showJadeCounter.state == NSOnState
        }
    }
}

// MARK: - MASPreferencesViewController
extension PlayerTrackersPreferences: MASPreferencesViewController {
    var viewIdentifier: String {
        return "player_trackers"
    }

    var toolbarItemImage: NSImage? {
        return NSImage(named: NSImageNameAdvanced)
    }

    var toolbarItemLabel: String? {
        return NSLocalizedString("Player tracker", comment: "")
    }
}
