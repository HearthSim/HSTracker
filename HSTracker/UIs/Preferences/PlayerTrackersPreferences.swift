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
    @IBOutlet weak var showGalakrondInvokeCounter: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        showPlayerTracker.state = Settings.showPlayerTracker ? .on : .off
        showPlayerCardCount.state = Settings.showPlayerCardCount ? .on : .off
        showPlayerDrawChance.state = Settings.showPlayerDrawChance ? .on : .off
        showPlayerGet.state = Settings.showPlayerGet ? .on : .off
        showCthunCounter.state = Settings.showPlayerCthun ? .on : .off
        showSpellCounter.state = Settings.showPlayerSpell ? .on : .off
        showDeathrattleCounter.state = Settings.showPlayerDeathrattle ? .on : .off
        flashOnDraw.state = Settings.flashOnDraw ? .on : .off
        showRecord.state = Settings.showWinLossRatio ? .on : .off
        inHandColor.color = Settings.playerInHandColor
        showBoardDamage.state = Settings.playerBoardDamage ? .on : .off
        showDeckName.state = Settings.showDeckNameInTracker ? .on : .off
        showGraveyard.state = Settings.showPlayerGraveyard ? .on : .off
        showGraveyardDetails.state = Settings.showPlayerGraveyardDetails ? .on : .off
        showGraveyardDetails.isEnabled = showGraveyard.state == .on
        showJadeCounter.state = Settings.showPlayerJadeCounter ? .on : .off
        showGalakrondInvokeCounter.state = Settings.showPlayerGalakrondCounter ? .on : .off
    }
    
    @IBAction func colorChange(_ sender: NSColorWell) {
        if sender == inHandColor {
            Settings.playerInHandColor = inHandColor.color
        }
    }

    @IBAction func checkboxClicked(_ sender: NSButton) {
        if sender == showPlayerTracker {
            Settings.showPlayerTracker = showPlayerTracker.state == .on
        } else if sender == showPlayerGet {
            Settings.showPlayerGet = showPlayerGet.state == .on
        } else if sender == showPlayerCardCount {
            Settings.showPlayerCardCount = showPlayerCardCount.state == .on
        } else if sender == showPlayerDrawChance {
            Settings.showPlayerDrawChance = showPlayerDrawChance.state == .on
        } else if sender == showCthunCounter {
            Settings.showPlayerCthun = showCthunCounter.state == .on
        } else if sender == showSpellCounter {
            Settings.showPlayerSpell = showSpellCounter.state == .on
        } else if sender == showDeathrattleCounter {
            Settings.showPlayerDeathrattle = showDeathrattleCounter.state == .on
        } else if sender == flashOnDraw {
            Settings.flashOnDraw = flashOnDraw.state == .on
        } else if sender == showRecord {
            Settings.showWinLossRatio = showRecord.state == .on
        } else if sender == showBoardDamage {
            Settings.playerBoardDamage = showBoardDamage.state == .on
        } else if sender == showDeckName {
            Settings.showDeckNameInTracker = showDeckName.state == .on
        } else if sender == showGraveyard {
            Settings.showPlayerGraveyard = showGraveyard.state == .on
            if showGraveyard.state == .on {
                showGraveyardDetails.isEnabled = true
            } else {
                showGraveyardDetails.isEnabled = false
            }
        } else if sender == showGraveyardDetails {
            Settings.showPlayerGraveyardDetails = showGraveyardDetails.state == .on
        } else if sender == showJadeCounter {
            Settings.showPlayerJadeCounter = showJadeCounter.state == .on
        } else if sender == showGalakrondInvokeCounter {
            Settings.showPlayerGalakrondCounter = showGalakrondInvokeCounter.state == .on
        }
    }
}

// MARK: - MASPreferencesViewController
extension PlayerTrackersPreferences: MASPreferencesViewController {
    var viewIdentifier: String {
        return "player_trackers"
    }

    var toolbarItemImage: NSImage? {
        return NSImage(named: NSImage.Name.advanced)
    }

    var toolbarItemLabel: String? {
        return NSLocalizedString("Player tracker", comment: "")
    }
}
