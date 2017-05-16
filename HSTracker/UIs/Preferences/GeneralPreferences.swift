//
//  GeneralPreferences.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 29/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import MASPreferences

class GeneralPreferences: NSViewController {

    @IBOutlet weak var notifyGameStart: NSButton!
    @IBOutlet weak var notifyTurnStart: NSButton!
    @IBOutlet weak var notifyOpponentConcede: NSButton!
    @IBOutlet weak var closeTrackerWhenHSCloses: NSButton!
    @IBOutlet weak var promptNote: NSButton!
    @IBOutlet weak var saveReplays: NSButton!
    @IBOutlet weak var enableDockBadge: NSButton!
    @IBOutlet weak var preferGoldenCards: NSButton!
    @IBOutlet weak var useArenaHelper: NSButton!
    @IBOutlet weak var useToastNotifications: NSButton!
	
    override func viewDidLoad() {
        super.viewDidLoad()

        notifyGameStart.state = Settings.notifyGameStart ? NSOnState : NSOffState
        notifyTurnStart.state = Settings.notifyTurnStart ? NSOnState : NSOffState
        notifyOpponentConcede.state = Settings.notifyOpponentConcede ? NSOnState : NSOffState
        closeTrackerWhenHSCloses.state = Settings.quitWhenHearthstoneCloses ? NSOnState : NSOffState
        //promptNote.state = Settings.promptNotes ? NSOnState : NSOffState
        saveReplays.state = Settings.saveReplays ? NSOnState : NSOffState
        enableDockBadge.state = Settings.showAppHealth ? NSOnState : NSOffState
        preferGoldenCards.state = Settings.preferGoldenCards ? NSOnState : NSOffState
        useArenaHelper.state = Settings.showArenaHelper ? NSOnState : NSOffState
		useToastNotifications.state = Settings.useToastNotification ? NSOnState : NSOffState
    }

    @IBAction func checkboxClicked(_ sender: NSButton) {
        if sender == notifyGameStart {
            Settings.notifyGameStart = notifyGameStart.state == NSOnState
        } else if sender == notifyTurnStart {
            Settings.notifyTurnStart = notifyTurnStart.state == NSOnState
        } else if sender == notifyOpponentConcede {
            Settings.notifyOpponentConcede = notifyOpponentConcede.state == NSOnState
        } else if sender == closeTrackerWhenHSCloses {
            Settings.quitWhenHearthstoneCloses = closeTrackerWhenHSCloses.state == NSOnState
        //} else if sender == promptNote {
        //    Settings.promptNotes = promptNote.state == NSOnState
        } else if sender == saveReplays {
            Settings.saveReplays = saveReplays.state == NSOnState
        } else if sender == enableDockBadge {
            Settings.showAppHealth = enableDockBadge.state == NSOnState
            AppHealth.instance.updateBadge()
        } else if sender == preferGoldenCards {
            Settings.preferGoldenCards = preferGoldenCards.state == NSOnState
        } else if sender == useArenaHelper {
            Settings.showArenaHelper = useArenaHelper.state == NSOnState
		} else if sender == useToastNotifications {
			Settings.useToastNotification = useToastNotifications.state == NSOnState
		}
    }

}
// MARK: - MASPreferencesViewController
extension GeneralPreferences: MASPreferencesViewController {
    override var identifier: String? {
        get {
            return "general"
        }
        set {
            super.identifier = newValue
        }
    }

    var toolbarItemImage: NSImage? {
        return NSImage(named: NSImageNameAdvanced)

    }

    var toolbarItemLabel: String? {
        return NSLocalizedString("General", comment: "")
    }
}
