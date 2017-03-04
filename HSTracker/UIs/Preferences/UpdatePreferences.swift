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
    
    public static let dateStringFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ssZZZZZ"
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        autoDownloadsUpdates.state = Settings.automaticallyDownloadsUpdates ? NSOnState : NSOffState
        releaseChannel.selectItem(at: Settings.releaseChannel.rawValue)
        if let lastUpdateCheckDate = sparkleUpdater.lastUpdateCheckDate {
            lastUpdate.stringValue = UpdatePreferences.dateStringFormatter.string(from: lastUpdateCheckDate)
        }
    }
    
    @IBAction func changeChannel(_ sender: AnyObject) {
        if let release = ReleaseChannel(rawValue: releaseChannel.indexOfSelectedItem) {
            Settings.releaseChannel = release
        } else {
            Settings.releaseChannel = .beta
        }
    }
    
    @IBAction func checkboxClicked(_ sender: NSButton) {
        if sender == autoDownloadsUpdates {
            Settings.automaticallyDownloadsUpdates = autoDownloadsUpdates.state == NSOnState
            sparkleUpdater.automaticallyDownloadsUpdates = Settings.automaticallyDownloadsUpdates
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
