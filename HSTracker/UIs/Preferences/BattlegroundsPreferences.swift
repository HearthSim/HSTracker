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
    @IBOutlet weak var showSessionRecap: NSButton!
    @IBOutlet weak var showBannedTribes: NSButton!
    @IBOutlet weak var showMMR: NSButton!
    @IBOutlet weak var showMMRStartCurrent: NSButton!
    @IBOutlet weak var showMMRCurrentChange: NSButton!
    @IBOutlet weak var showLatestGames: NSButton!
    
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
        showSessionRecap.state = Settings.showSessionRecap ? .on : .off
        showBannedTribes.state = Settings.showBannedTribes ? .on : .off
        showMMR.state = Settings.showMMR ? .on : .off
        showLatestGames.state = Settings.showLatestGames ? .on : .off
        showMMRStartCurrent.state = Settings.showMMRStartCurrent ? .on : .off
        showMMRCurrentChange.state = Settings.showMMRStartCurrent ? .off : .on
        updateSessionRecapEnablement()
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
        } else if sender == showSessionRecap {
            Settings.showSessionRecap = sender.state == .on
            updateSessionRecapEnablement()
        } else if sender == showBannedTribes {
            Settings.showBannedTribes = sender.state == .on
        } else if sender == showMMR {
            Settings.showMMR = sender.state == .on
            updateSessionRecapEnablement()
        } else if sender == showLatestGames {
            Settings.showLatestGames = sender.state == .on
        } else if sender == showMMRStartCurrent {
            Settings.showMMRStartCurrent = true
            showMMRStartCurrent.state = .on
            showMMRCurrentChange.state = .off
        } else if sender == showMMRCurrentChange {
            Settings.showMMRStartCurrent = false
            showMMRStartCurrent.state = .off
            showMMRCurrentChange.state = .on
        }
    }
    
    private func updateSessionRecapEnablement() {
        var enabled = showSessionRecap.state == .on
        showBannedTribes.isEnabled = enabled
        showMMR.isEnabled = enabled
        showLatestGames.isEnabled = enabled
        showMMRStartCurrent.isEnabled = enabled
        showMMRCurrentChange.isEnabled = enabled
        if enabled {
            enabled = showMMR.state == .on
            showMMRStartCurrent.isEnabled = enabled
            showMMRCurrentChange.isEnabled = enabled
        }
        
    }
    
    @IBAction func reset(_ sender: NSButton) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = NSLocalizedString("Resetting current Session", comment: "")
        alert.informativeText = NSLocalizedString("By clicking 'Reset' you will clear your list of Latest Games and make your Start MMR the same as your current MMR.", comment: "")
        alert.addButton(withTitle: NSLocalizedString("Reset", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        
        if alert.runModal() != NSApplication.ModalResponse.alertFirstButtonReturn {
            return
        }
        
        BattlegroundsLastGames.instance.reset()
        AppDelegate.instance().coreManager.game.updateBattlegroundsSessionOverlay()

    }
}

// MARK: - Preferences

extension Preferences.PaneIdentifier {
    static let battlegrounds = Self("battlegrounds")
}
