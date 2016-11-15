//
//  HSReplayPreferences.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 13/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import MASPreferences
import CleanroomLogger

class HSReplayPreferences: NSViewController {
    @IBOutlet weak var synchronizeMatches: NSButton!
    @IBOutlet weak var hsReplayAccountStatus: NSTextField!
    @IBOutlet weak var claimAccountButton: NSButtonCell!
    @IBOutlet weak var claimAccountInfo: NSTextField!
    @IBOutlet weak var disconnectButton: NSButton!
    @IBOutlet weak var showPushNotification: NSButton!
    private var getAccountTimer: Timer?
    private var requests = 0
    private let maxRequests = 10
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let settings = Settings.instance
        
        synchronizeMatches.state = settings.hsReplaySynchronizeMatches ? NSOnState : NSOffState
        showPushNotification.state = settings.showHSReplayPushNotification ? NSOnState : NSOffState
        updateStatus()
    }
    
    override func viewDidDisappear() {
        getAccountTimer?.invalidate()
    }
    
    @IBAction func checkboxClicked(_ sender: NSButton) {
        let settings = Settings.instance
        
        if sender == synchronizeMatches {
            settings.hsReplaySynchronizeMatches = synchronizeMatches.state == NSOnState
        } else if sender == showPushNotification {
            settings.showHSReplayPushNotification = showPushNotification.state == NSOnState
        }
    }
    
    @IBAction func disconnectAccount(_ sender: AnyObject) {
        Settings.instance.hsReplayUsername = nil
        Settings.instance.hsReplayId = nil
        updateStatus()
    }
    
    @IBAction func claimAccount(_ sender: AnyObject) {
        claimAccountButton.isEnabled = false
        requests = 0
        HSReplayAPI.getUploadToken { _ in
            HSReplayAPI.claimAccount()
            self.getAccountTimer?.invalidate()
            self.getAccountTimer = Timer.scheduledTimer(timeInterval: 5,
                target: self,
                selector: #selector(self.checkAccountInfo),
                userInfo: nil,
                repeats: true)
        }
    }
    
    @objc private func checkAccountInfo() {
        guard requests < maxRequests else {
            Log.warning?.message("max request for checking account info")
            return
        }
        
        HSReplayAPI.updateAccountStatus() { (status) in
            self.requests += 1
            if status {
                self.getAccountTimer?.invalidate()
            }
            self.updateStatus()
        }
    }
    
    private func updateStatus() {
        if let username = Settings.instance.hsReplayUsername {
            hsReplayAccountStatus.stringValue =
                String(format: NSLocalizedString("Connected as %@", comment: ""), username)
            claimAccountInfo.isEnabled = false
            claimAccountButton.isEnabled = false
            disconnectButton.isEnabled = true
        } else {
            claimAccountInfo.isEnabled = true
            claimAccountButton.isEnabled = true
            disconnectButton.isEnabled = false
            hsReplayAccountStatus.stringValue = NSLocalizedString("Account status : Anonymous",
                                                                  comment: "")
        }
    }
}

// MARK: - MASPreferencesViewController
extension HSReplayPreferences: MASPreferencesViewController {
    override var identifier: String? {
        get {
            return "hsreplay"
        }
        set {
            super.identifier = newValue
        }
    }
    
    var toolbarItemImage: NSImage? {
        return NSImage(named: "hsreplay_icon")
    }
    
    var toolbarItemLabel: String? {
        return "HSReplay"
    }
}
