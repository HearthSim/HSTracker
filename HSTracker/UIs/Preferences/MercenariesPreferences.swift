//
//  TrackersPreferences.swift
//  HSTracker
//
//  Created by Francisco Moraes on 18/10/20.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Preferences

class MercenariesPreferences: NSViewController, PreferencePane {
    var preferencePaneIdentifier = Preferences.PaneIdentifier.mercenaries
    
    var preferencePaneTitle = String.localizedString("Mercenaries", comment: "")
    
    var toolbarItemIcon = NSImage(named: "Mode_Mercenaries")!

    @IBOutlet weak var showMercsOpponentHover: NSButton!
    @IBOutlet weak var showMercsPlayerHover: NSButton!
    @IBOutlet weak var showMercsTasks: NSButton!
    @IBOutlet weak var showMercsOpponentAbilities: NSButton!
    @IBOutlet weak var showMercsPlayerAbilities: NSButton!
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        guard showMercsOpponentHover != nil else {
            return
        }
        showMercsOpponentHover.state = Settings.showBobsBuddy ? .on : .off
        showMercsPlayerHover.state = Settings.showBobsBuddyDuringCombat ? .on : .off
        showMercsTasks.state = Settings.showMercsTasks ? .on : .off
        showMercsOpponentAbilities.state = Settings.showMercsOpponentAbilities ? .on : .off
        showMercsPlayerAbilities.state = Settings.showMercsPlayerAbilities ? .on : .off
    }

    @IBAction func checkboxClicked(_ sender: NSButton) {
        if sender == showMercsOpponentHover {
            Settings.showMercsOpponentHover = sender.state == .on
        } else if sender == showMercsPlayerHover {
            Settings.showMercsPlayerHover = sender.state == .on
        } else if sender == showMercsTasks {
            Settings.showMercsTasks = sender.state == .on
            if Settings.showMercsTasks {
                AppDelegate.instance().coreManager.game.updateMercenariesTaskListButton()
            } else {
                AppDelegate.instance().coreManager.game.updateMercenariesTaskListButton()
            }
        } else if sender == showMercsOpponentAbilities {
            Settings.showMercsOpponentAbilities = sender.state == .on
            AppDelegate.instance().coreManager.game.updateBoardOverlay()
        } else if sender == showMercsPlayerAbilities {
            Settings.showMercsPlayerAbilities = sender.state == .on
            AppDelegate.instance().coreManager.game.updateBoardOverlay()
        }
    }
}

// MARK: - Preferences

extension Preferences.PaneIdentifier {
    static let mercenaries = Self("mercenaries")
}
