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
    
    var preferencePaneTitle = NSLocalizedString("Mercenaries", comment: "")
    
    var toolbarItemIcon = NSImage(named: "Mode_Mercenaries")!

    @IBOutlet weak var showMercsOpponentHover: NSButton!
    @IBOutlet weak var showMercsPlayerHover: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showMercsOpponentHover.state = Settings.showBobsBuddy ? .on : .off
        showMercsPlayerHover.state = Settings.showBobsBuddyDuringCombat ? .on : .off
    }

    @IBAction func checkboxClicked(_ sender: NSButton) {
        if sender == showMercsOpponentHover {
            Settings.showMercsOpponentHover = showMercsOpponentHover.state == .on
        } else if sender == showMercsPlayerHover {
            Settings.showMercsPlayerHover = showMercsPlayerHover.state == .on
        }
    }
}

// MARK: - Preferences

extension Preferences.PaneIdentifier {
    static let mercenaries = Self("mercenaries")
}
