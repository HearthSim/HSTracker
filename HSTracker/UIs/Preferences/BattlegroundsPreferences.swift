//
//  TrackersPreferences.swift
//  HSTracker
//
//  Created by Francisco Moraes on 18/10/20.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import MASPreferences

class BattlegroundsPreferences: NSViewController {

    @IBOutlet weak var showBobsBuddy: NSButton!
    @IBOutlet weak var showBobsBuddyDuringCombat: NSButton!
    @IBOutlet weak var showBobsBuddyDuringShopping: NSButton!
    @IBOutlet weak var showTurnCounter: NSButton!
    @IBOutlet weak var showAverageDamage: NSButton!
    @IBOutlet weak var showOpponentWarband: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showBobsBuddy.state = Settings.showBobsBuddy ? .on : .off
        showBobsBuddyDuringCombat.state = Settings.showBobsBuddyDuringCombat ? .on : .off
        showBobsBuddyDuringShopping.state = Settings.showBobsBuddyDuringShopping ? .on : .off
        showTurnCounter.state = Settings.showTurnCounter ? .on : .off
        showAverageDamage.state = Settings.showAverageDamage ? .on : .off
        showOpponentWarband.state = Settings.showOpponentWarband ? .on : .off
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
        }
    }
}

// MARK: - MASPreferencesViewController

extension BattlegroundsPreferences: MASPreferencesViewController {
    var viewIdentifier: String {
        return "battlegrounds"
    }

    var toolbarItemImage: NSImage? {
        return NSImage(named: NSImage.Name.advanced)
    }

    var toolbarItemLabel: String? {
        return NSLocalizedString("Battlegrounds", comment: "")
    }
}
