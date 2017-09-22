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
        showOpponentTracker.state = Settings.showOpponentTracker ? .on : .off
        showCardHuds.state = Settings.showCardHuds ? .on : .off
        clearTrackersOnGameEnd.state = Settings.clearTrackersOnGameEnd ? .on : .off
        showOpponentCardCount.state = Settings.showOpponentCardCount ? .on : .off
        showOpponentDrawChance.state = Settings.showOpponentDrawChance ? .on : .off
        showCthunCounter.state = Settings.showOpponentCthun ? .on : .off
        showSpellCounter.state = Settings.showOpponentSpell ? .on : .off
        includeCreated.state = Settings.showOpponentCreated ? .on : .off
        showDeathrattleCounter.state = Settings.showOpponentDeathrattle ? .on : .off
        showPlayerClass.state = Settings.showOpponentClassInTracker ? .on : .off
        showBoardDamage.state = Settings.opponentBoardDamage ? .on : .off
        showGraveyard.state = Settings.showOpponentGraveyard ? .on : .off
        showGraveyardDetails.state = Settings.showOpponentGraveyardDetails ? .on : .off
        showGraveyardDetails.isEnabled = showGraveyard.state == .on
        showJadeCounter.state = Settings.showOpponentJadeCounter ? .on : .off
    }

    @IBAction func checkboxClicked(_ sender: NSButton) {
        if sender == showOpponentTracker {
            Settings.showOpponentTracker = showOpponentTracker.state == .on
        } else if sender == showCardHuds {
            Settings.showCardHuds = showCardHuds.state == .on
        } else if sender == clearTrackersOnGameEnd {
            Settings.clearTrackersOnGameEnd = clearTrackersOnGameEnd.state == .on
        } else if sender == showOpponentCardCount {
            Settings.showOpponentCardCount = showOpponentCardCount.state == .on
        } else if sender == showOpponentDrawChance {
            Settings.showOpponentDrawChance = showOpponentDrawChance.state == .on
        } else if sender == showCthunCounter {
            Settings.showOpponentCthun = showCthunCounter.state == .on
        } else if sender == showSpellCounter {
            Settings.showOpponentSpell = showSpellCounter.state == .on
        } else if sender == includeCreated {
            Settings.showOpponentCreated = includeCreated.state == .on
        } else if sender == showDeathrattleCounter {
            Settings.showOpponentDeathrattle = showDeathrattleCounter.state == .on
        } else if sender == showPlayerClass {
            Settings.showOpponentClassInTracker = showPlayerClass.state == .on
        } else if sender == showBoardDamage {
            Settings.opponentBoardDamage = showBoardDamage.state == .on
        } else if sender == showGraveyard {
            Settings.showOpponentGraveyard = showGraveyard.state == .on
            if showGraveyard.state == .on {
                showGraveyardDetails.isEnabled = true
            } else {
                showGraveyardDetails.isEnabled = false
            }
        } else if sender == showGraveyardDetails {
            Settings.showOpponentGraveyardDetails = showGraveyardDetails.state == .on
        } else if sender == showJadeCounter {
            Settings.showOpponentJadeCounter = showJadeCounter.state == .on
        }
    }
}

// MARK: - MASPreferencesViewController
extension OpponentTrackersPreferences: MASPreferencesViewController {
    var viewIdentifier: String {
        return "opponent_trackers"
    }

    var toolbarItemImage: NSImage? {
        return NSImage(named: NSImage.Name.advanced)
    }

    var toolbarItemLabel: String? {
        return NSLocalizedString("Opponent tracker", comment: "")
    }
}
