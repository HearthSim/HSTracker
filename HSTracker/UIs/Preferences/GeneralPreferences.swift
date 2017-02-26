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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let settings = Settings.instance
        notifyGameStart.state = settings.notifyGameStart ? NSOnState : NSOffState
        notifyTurnStart.state = settings.notifyTurnStart ? NSOnState : NSOffState
        notifyOpponentConcede.state = settings.notifyOpponentConcede ? NSOnState : NSOffState
        closeTrackerWhenHSCloses.state = settings.quitWhenHearthstoneCloses ? NSOnState : NSOffState
        promptNote.state = settings.promptNotes ? NSOnState : NSOffState
        saveReplays.state = settings.saveReplays ? NSOnState : NSOffState
        enableDockBadge.state = settings.showAppHealth ? NSOnState : NSOffState
        preferGoldenCards.state = settings.preferGoldenCards ? NSOnState : NSOffState
        useArenaHelper.state = settings.showArenaHelper ? NSOnState : NSOffState
    }

    @IBAction func checkboxClicked(_ sender: NSButton) {
        let settings = Settings.instance
        if sender == notifyGameStart {
            settings.notifyGameStart = notifyGameStart.state == NSOnState
        } else if sender == notifyTurnStart {
            settings.notifyTurnStart = notifyTurnStart.state == NSOnState
        } else if sender == notifyOpponentConcede {
            settings.notifyOpponentConcede = notifyOpponentConcede.state == NSOnState
        } else if sender == closeTrackerWhenHSCloses {
            settings.quitWhenHearthstoneCloses = closeTrackerWhenHSCloses.state == NSOnState
        } else if sender == promptNote {
            settings.promptNotes = promptNote.state == NSOnState
        } else if sender == saveReplays {
            settings.saveReplays = saveReplays.state == NSOnState
        } else if sender == enableDockBadge {
            settings.showAppHealth = enableDockBadge.state == NSOnState
            AppHealth.instance.updateBadge()
        } else if sender == preferGoldenCards {
            settings.preferGoldenCards = preferGoldenCards.state == NSOnState
        } else if sender == useArenaHelper {
            settings.showArenaHelper = useArenaHelper.state == NSOnState
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
