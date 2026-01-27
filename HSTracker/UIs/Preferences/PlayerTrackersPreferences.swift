//
//  TrackersPreferences.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 29/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Preferences

class PlayerTrackersPreferences: NSViewController, PreferencePane {
    var preferencePaneIdentifier = Preferences.PaneIdentifier.player_trackers
    
    var preferencePaneTitle = String.localizedString("Player tracker", comment: "")
    
    var toolbarItemIcon = NSImage(named: "player")!

    @IBOutlet var showPlayerTracker: NSButton!
    @IBOutlet var showPlayerCardCount: NSButton!
    @IBOutlet var showPlayerDrawChance: NSButton!
    @IBOutlet var showPlayerGet: NSButton!
    @IBOutlet var showDeathrattleCounter: NSButton!
    @IBOutlet var flashOnDraw: NSButton!
    @IBOutlet var showRecord: NSButton!
    @IBOutlet var inHandColor: NSColorWell!
    @IBOutlet var showBoardDamage: NSButton!
    @IBOutlet var showDeckName: NSButton!
    @IBOutlet var showGraveyard: NSButton!
    @IBOutlet var showGraveyardDetails: NSButton!
    @IBOutlet var showTopCards: NSButton!
    @IBOutlet var showBottomCards: NSButton!
    @IBOutlet var showPlayerSideboards: NSButton!
    @IBOutlet var showActiveEffects: NSButton!
    @IBOutlet var showCounters: NSButton!
    @IBOutlet var showPlayerRelatedCards: NSButton!
    @IBOutlet var showPlayerHighlightSynergies: NSButton!
    @IBOutlet var showPlayerMaxResources: NSButton!

    override func viewWillAppear() {
        super.viewWillAppear()
        
        guard showPlayerTracker != nil else {
            return
        }
        
        showPlayerTracker.state = Settings.showPlayerTracker ? .on : .off
        showPlayerCardCount.state = Settings.showPlayerCardCount ? .on : .off
        showPlayerDrawChance.state = Settings.showPlayerDrawChance ? .on : .off
        showPlayerGet.state = Settings.showPlayerGet ? .on : .off
        showDeathrattleCounter.state = Settings.showPlayerDeathrattle ? .on : .off
        flashOnDraw.state = Settings.flashOnDraw ? .on : .off
        showRecord.state = Settings.showWinLossRatio ? .on : .off
        inHandColor.color = Settings.playerInHandColor
        showBoardDamage.state = Settings.playerBoardDamage ? .on : .off
        showDeckName.state = Settings.showDeckNameInTracker ? .on : .off
        showGraveyard.state = Settings.showPlayerGraveyard ? .on : .off
        showGraveyardDetails.state = Settings.showPlayerGraveyardDetails ? .on : .off
        showGraveyardDetails.isEnabled = showGraveyard.state == .on
        showTopCards.state = Settings.showPlayerCardsTop ? .on : .off
        showBottomCards.state = Settings.showPlayerCardsBottom ? .on : .off
        showPlayerSideboards.state = Settings.hidePlayerSideboards ? .off : .on
        showActiveEffects.state = Settings.showPlayerActiveEffects ? .on : .off
        showCounters.state = Settings.showPlayerCounters ? .on : .off
        showPlayerRelatedCards.state = Settings.showPlayerRelatedCards ? .on : .off
        showPlayerHighlightSynergies.state = Settings.showPlayerHighlightSynergies ? .on : .off
        showPlayerMaxResources.state = Settings.showPlayerMaxResources ? .on : .off
    }
    
    @IBAction func colorChange(_ sender: NSColorWell) {
        if sender == inHandColor {
            Settings.playerInHandColor = inHandColor.color.usingColorSpace(.sRGB) ?? NSColor(red: 0.678, green: 1, blue: 0.184, alpha: 1)
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
        } else if sender == showTopCards {
            Settings.showPlayerCardsTop = showTopCards.state == .on
        } else if sender == showBottomCards {
            Settings.showPlayerCardsBottom = showBottomCards.state == .on
        } else if sender == showPlayerSideboards {
            Settings.hidePlayerSideboards = showPlayerSideboards.state == .off
        } else if sender == showActiveEffects {
            Settings.showPlayerActiveEffects = showActiveEffects.state == .on
        } else if sender == showCounters {
            Settings.showPlayerCounters = showCounters.state == .on
        } else if sender == showPlayerRelatedCards {
            Settings.showPlayerRelatedCards = showPlayerRelatedCards.state == .on
        } else if sender == showPlayerHighlightSynergies {
            Settings.showPlayerHighlightSynergies = showPlayerHighlightSynergies.state == .on
        } else if sender == showPlayerMaxResources {
            Settings.showPlayerMaxResources = showPlayerMaxResources.state == .on
        }
    }
}

// MARK: - Preferences
extension Preferences.PaneIdentifier {
    static let player_trackers = Self("player_trackers")
}
