//
//  GeneralPreferences.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 29/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import MASPreferences

class GeneralPreferences: NSViewController, MASPreferencesViewController {

    @IBOutlet weak var notifyGameStart: NSButton!
    @IBOutlet weak var notifyTurnStart: NSButton!
    @IBOutlet weak var notifyOpponentConcede: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        let settings = Settings.instance
        notifyGameStart.state = settings.notifyGameStart ? NSOnState : NSOffState
        notifyTurnStart.state = settings.notifyTurnStart ? NSOnState : NSOffState
        notifyOpponentConcede.state = settings.notifyOpponentConcede ? NSOnState : NSOffState
    }

    @IBAction func checkboxClicked(sender: NSButton) {
        let settings = Settings.instance
        if sender == notifyGameStart {
            settings.notifyGameStart = notifyGameStart.state == NSOnState
        } else if sender == notifyTurnStart {
            settings.notifyTurnStart = notifyTurnStart.state == NSOnState
        } else if sender == notifyOpponentConcede {
            settings.notifyOpponentConcede = notifyOpponentConcede.state == NSOnState
        }
    }

    // MARK: - MASPreferencesViewController
    override var identifier: String? {
        get {
            return "general"
        }
        set {
            super.identifier = newValue
        }
    }

    var toolbarItemImage: NSImage! {
        return NSImage(named: NSImageNameAdvanced)

    }

    var toolbarItemLabel: String! {
        return NSLocalizedString("General", comment: "")
    }
}
