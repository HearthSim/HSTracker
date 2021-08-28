//
//  TrackersPreferences.swift
//  HSTracker
//
//  Created by Francisco Moraes on 18/10/20.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Preferences

class BattlegroundsPreferences: NSViewController, PreferencePane {
    var preferencePaneIdentifier = Preferences.PaneIdentifier.battlegrounds
    
    var preferencePaneTitle = NSLocalizedString("Battlegrounds", comment: "")
    
    var toolbarItemIcon = NSImage(named: "Mode_Battlegrounds_Dark")!

    @IBOutlet weak var showBobsBuddy: NSButton!
    @IBOutlet weak var showBobsBuddyDuringCombat: NSButton!
    @IBOutlet weak var showBobsBuddyDuringShopping: NSButton!
    @IBOutlet weak var showTurnCounter: NSButton!
    @IBOutlet weak var showAverageDamage: NSButton!
    @IBOutlet weak var showOpponentWarband: NSButton!
    @IBOutlet weak var showTiers: NSButton!
    @IBOutlet weak var showTavernTriples: NSButton!
    @IBOutlet weak var showHeroToast: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showBobsBuddy.state = Settings.showBobsBuddy ? .on : .off
        showBobsBuddyDuringCombat.state = Settings.showBobsBuddyDuringCombat ? .on : .off
        showBobsBuddyDuringShopping.state = Settings.showBobsBuddyDuringShopping ? .on : .off
        showTurnCounter.state = Settings.showTurnCounter ? .on : .off
        showAverageDamage.state = Settings.showAverageDamage ? .on : .off
        showOpponentWarband.state = Settings.showOpponentWarband ? .on : .off
        showTiers.state = Settings.showTiers ? .on : .off
        showTavernTriples.state = Settings.showTavernTriples ? .on : .off
        showHeroToast.state = Settings.showHeroToast ? .on : .off
    }

    @IBAction func checkboxClicked(_ sender: NSButton) {
        if sender == showBobsBuddy {
            Settings.showBobsBuddy = showBobsBuddy.state == .on
        } else if sender == showBobsBuddyDuringCombat {
            Settings.showBobsBuddyDuringCombat = showBobsBuddyDuringCombat.state == .on
        } else if sender == showBobsBuddyDuringShopping {
            Settings.showBobsBuddyDuringShopping = showBobsBuddyDuringShopping.state == .on
        } else if sender == showTurnCounter {
            Settings.showTurnCounter = showTurnCounter.state == .on
        } else if sender == showAverageDamage {
            Settings.showAverageDamage = showAverageDamage.state == .on
        } else if sender == showOpponentWarband {
            Settings.showOpponentWarband = showOpponentWarband.state == .on
        } else if sender == showTiers {
            Settings.showTiers = showTiers.state == .on
        } else if sender == showTavernTriples {
            Settings.showTavernTriples = showTavernTriples.state == .on
        } else if sender == showHeroToast {
            Settings.showHeroToast = showHeroToast.state == .on
        }
    }
}

// MARK: - Preferences

extension Preferences.PaneIdentifier {
    static let battlegrounds = Self("battlegrounds")
}
