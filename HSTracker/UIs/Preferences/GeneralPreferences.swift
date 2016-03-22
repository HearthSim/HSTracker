//
//  GeneralPreferences.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 29/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import MASPreferences

class GeneralPreferences : NSViewController, MASPreferencesViewController {
    
    @IBOutlet weak var autoPositionTrackers: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let settings = Settings.instance
        
        autoPositionTrackers.state = settings.autoPositionTrackers ? NSOnState : NSOffState
    }
    
    @IBAction func checkboxClicked(sender: NSButton) {
        let settings = Settings.instance
        if sender == autoPositionTrackers {
            settings.autoPositionTrackers = autoPositionTrackers.state == NSOnState
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