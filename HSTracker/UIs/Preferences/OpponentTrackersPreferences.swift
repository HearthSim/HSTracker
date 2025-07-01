//
//  TrackersPreferences.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 29/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Preferences

class OpponentTrackersPreferences: NSViewController, PreferencePane {
    var preferencePaneIdentifier = Preferences.PaneIdentifier.opponent_trackers
    
    var preferencePaneTitle = String.localizedString("Opponent tracker", comment: "")
    
    var toolbarItemIcon = NSImage(named: "opponent")!

    @IBOutlet var showOpponentTracker: NSButton!
    @IBOutlet var showCardHuds: NSButton!
    @IBOutlet var clearTrackersOnGameEnd: NSButton!
    @IBOutlet var showOpponentCardCount: NSButton!
    @IBOutlet var showOpponentDrawChance: NSButton!
    @IBOutlet var includeCreated: NSButton!
    @IBOutlet var showDeathrattleCounter: NSButton!
    @IBOutlet var showPlayerClass: NSButton!
    @IBOutlet var showBoardDamage: NSButton!
    @IBOutlet var showGraveyard: NSButton!
    @IBOutlet var showGraveyardDetails: NSButton!
    @IBOutlet var preventOpponentNameCovering: NSButton!
    @IBOutlet var enableLinkOpponentDeckInNonFriendly: NSButton!
    @IBOutlet var showActiveEffects: NSButton!
    @IBOutlet var showCounters: NSButton!
    @IBOutlet var showPlayerRelatedCards: NSButton!
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        guard showOpponentTracker != nil else {
            return
        }
        
        showOpponentTracker.state = Settings.showOpponentTracker ? .on : .off
        showCardHuds.state = Settings.showCardHuds ? .on : .off
        clearTrackersOnGameEnd.state = Settings.clearTrackersOnGameEnd ? .on : .off
        showOpponentCardCount.state = Settings.showOpponentCardCount ? .on : .off
        showOpponentDrawChance.state = Settings.showOpponentDrawChance ? .on : .off
        includeCreated.state = Settings.showOpponentCreated ? .on : .off
        showDeathrattleCounter.state = Settings.showOpponentDeathrattle ? .on : .off
        showPlayerClass.state = Settings.showOpponentClassInTracker ? .on : .off
        showBoardDamage.state = Settings.opponentBoardDamage ? .on : .off
        showGraveyard.state = Settings.showOpponentGraveyard ? .on : .off
        showGraveyardDetails.state = Settings.showOpponentGraveyardDetails ? .on : .off
        showGraveyardDetails.isEnabled = showGraveyard.state == .on
        preventOpponentNameCovering.state = Settings.preventOpponentNameCovering ? .on : .off
        enableLinkOpponentDeckInNonFriendly.state = Settings.enableLinkOpponentDeckInNonFriendly ? .on : .off
        showActiveEffects.state = Settings.showOpponentActiveEffects ? .on : .off
        showCounters.state = Settings.showOpponentCounters ? .on : .off
        showPlayerRelatedCards.state = Settings.showOpponentRelatedCards ? .on : .off
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
        } else if sender == preventOpponentNameCovering {
            Settings.preventOpponentNameCovering = preventOpponentNameCovering.state == .on
        } else if sender == enableLinkOpponentDeckInNonFriendly {
            Settings.enableLinkOpponentDeckInNonFriendly = enableLinkOpponentDeckInNonFriendly.state == .on
        } else if sender == showActiveEffects {
            Settings.showOpponentActiveEffects = showActiveEffects.state == .on
        } else if sender == showCounters {
            Settings.showOpponentCounters = showCounters.state == .on
        } else if sender == showPlayerRelatedCards {
            Settings.showOpponentRelatedCards = showPlayerRelatedCards.state == .on
        }
    }
}

// MARK: - Preferences
extension Preferences.PaneIdentifier {
    static let opponent_trackers = Self("opponent_trackers")
}
