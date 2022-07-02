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
    
    var preferencePaneTitle = NSLocalizedString("Player tracker", comment: "")
    
    var toolbarItemIcon = NSImage(named: "player")!

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
    @IBOutlet weak var showLibramCounter: NSButton!
    @IBOutlet weak var showAbyssalCounter: NSButton!
    @IBOutlet weak var showTopCards: NSButton!
    @IBOutlet weak var showBottomCards: NSButton!

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
        showLibramCounter.state = Settings.showPlayerLibramCounter ? .on : .off
        showAbyssalCounter.state = Settings.showPlayerAbyssalCounter ? .on : .off
        showTopCards.state = Settings.showPlayerCardsTop ? .on : .off
        showBottomCards.state = Settings.showPlayerCardsBottom ? .on : .off
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
        } else if sender == showLibramCounter {
            Settings.showPlayerLibramCounter = showLibramCounter.state == .on
        } else if sender == showAbyssalCounter {
            Settings.showPlayerAbyssalCounter = showAbyssalCounter.state == .on
        } else if sender == showTopCards {
            Settings.showPlayerCardsTop = showTopCards.state == .on
        } else if sender == showBottomCards {
            Settings.showPlayerCardsBottom = showBottomCards.state == .on
        }
    }
}

// MARK: - Preferences
extension Preferences.PaneIdentifier {
    static let player_trackers = Self("player_trackers")
}
