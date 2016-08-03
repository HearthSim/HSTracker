//
//  TrackOBotPreferences.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 3/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import MASPreferences

class TrackOBotPreferences: NSViewController {
    
    @IBOutlet weak var synchronizeMatches: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let settings = Settings.instance
        
        synchronizeMatches.state = settings.trackobotSynchronizeMatches ? NSOnState : NSOffState
    }
    
    @IBAction func checkboxClicked(sender: NSButton) {
        let settings = Settings.instance
        if sender == synchronizeMatches {
            settings.trackobotSynchronizeMatches = synchronizeMatches.state == NSOnState
        }
    }
}

// MARK: - MASPreferencesViewController
extension TrackOBotPreferences: MASPreferencesViewController {
    override var identifier: String? {
        get {
            return "trackobot"
        }
        set {
            super.identifier = newValue
        }
    }
    
    var toolbarItemImage: NSImage! {
        return NSImage(named: "trackobot_icon")
    }
    
    var toolbarItemLabel: String! {
        return "Track-o-Bot"
    }
}