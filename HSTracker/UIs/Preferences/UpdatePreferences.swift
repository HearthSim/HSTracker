//
//  UpdatePreferences.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 31/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import MASPreferences

class UpdatePreferences: NSViewController {
    @IBOutlet weak var autoDownloadsUpdates: NSButton!
    @IBOutlet weak var releaseChannel: NSPopUpButton!
    @IBOutlet weak var lastUpdate: NSTextField!
    @IBOutlet var sparkleUpdater: SUUpdater!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let settings = Settings.instance
        autoDownloadsUpdates.state = settings.automaticallyDownloadsUpdates ? NSOnState : NSOffState
        releaseChannel.selectItemAtIndex(settings.releaseChannel.rawValue)
        lastUpdate.stringValue = sparkleUpdater.lastUpdateCheckDate.toLocalizedString()
    }
    
    @IBAction func changeChannel(sender: AnyObject) {
        let settings = Settings.instance
        if let release = ReleaseChannel(rawValue: releaseChannel.indexOfSelectedItem) {
            settings.releaseChannel = release
        } else {
            settings.releaseChannel = .beta
        }
    }
    
    @IBAction func checkboxClicked(sender: NSButton) {
        let settings = Settings.instance
        
        if sender == autoDownloadsUpdates {
            settings.automaticallyDownloadsUpdates = autoDownloadsUpdates.state == NSOnState
            sparkleUpdater.automaticallyDownloadsUpdates = settings.automaticallyDownloadsUpdates
        }
    }
}

// MARK: - MASPreferencesViewController
extension UpdatePreferences: MASPreferencesViewController {
    override var identifier: String? {
        get {
            return "update_preferences"
        }
        set {
            super.identifier = newValue
        }
    }
    
    var toolbarItemImage: NSImage? {
        return NSImage(named: "Sparkle")
    }
    
    var toolbarItemLabel: String? {
        return NSLocalizedString("Updates", comment: "")
    }
}