//
//  GeneralPreferences.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 29/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Preferences

class GeneralPreferences: NSViewController, PreferencePane {
    var preferencePaneIdentifier = Preferences.PaneIdentifier.general
    
    var preferencePaneTitle = String.localizedString("General", comment: "")
    
    var toolbarItemIcon = NSImage(named: NSImage.preferencesGeneralName)!

    @IBOutlet var notifyGameStart: NSButton!
    @IBOutlet var notifyTurnStart: NSButton!
    @IBOutlet var notifyOpponentConcede: NSButton!
    @IBOutlet var closeTrackerWhenHSCloses: NSButton!
    @IBOutlet var saveReplays: NSButton!
    @IBOutlet var enableDockBadge: NSButton!
    @IBOutlet var preferGoldenCards: NSButton!
    @IBOutlet var useToastNotifications: NSButton!
	
    override func viewWillAppear() {
        super.viewWillAppear()
        
        guard notifyGameStart != nil else {
            return
        }

        notifyGameStart.state = Settings.notifyGameStart ? .on : .off
        notifyTurnStart.state = Settings.notifyTurnStart ? .on : .off
        notifyOpponentConcede.state = Settings.notifyOpponentConcede ? .on : .off
        closeTrackerWhenHSCloses.state = Settings.quitWhenHearthstoneCloses ? .on : .off
        saveReplays.state = Settings.saveReplays ? .on : .off
        enableDockBadge.state = Settings.showAppHealth ? .on : .off
        preferGoldenCards.state = Settings.preferGoldenCards ? .on : .off
		useToastNotifications.state = Settings.useToastNotification ? .on : .off
    }

    @IBAction func checkboxClicked(_ sender: NSButton) {
        if sender == notifyGameStart {
            Settings.notifyGameStart = notifyGameStart.state == .on
        } else if sender == notifyTurnStart {
            Settings.notifyTurnStart = notifyTurnStart.state == .on
        } else if sender == notifyOpponentConcede {
            Settings.notifyOpponentConcede = notifyOpponentConcede.state == .on
        } else if sender == closeTrackerWhenHSCloses {
            Settings.quitWhenHearthstoneCloses = closeTrackerWhenHSCloses.state == .on
        } else if sender == saveReplays {
            Settings.saveReplays = saveReplays.state == .on
        } else if sender == enableDockBadge {
            Settings.showAppHealth = enableDockBadge.state == .on
            AppHealth.instance.updateBadge()
        } else if sender == preferGoldenCards {
            Settings.preferGoldenCards = preferGoldenCards.state == .on
		} else if sender == useToastNotifications {
			Settings.useToastNotification = useToastNotifications.state == .on
		}
    }

}
// MARK: - Preferences
extension Preferences.PaneIdentifier {
    static let general = Self("general")
}
