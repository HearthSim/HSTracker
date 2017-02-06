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
    @IBOutlet weak var gameTypeSelector: NSView!
    @IBOutlet weak var uploadRankedGames: NSButton!
    @IBOutlet weak var uploadCasualGames: NSButton!
    @IBOutlet weak var uploadArenaGames: NSButton!
    @IBOutlet weak var uploadBrawlGames: NSButton!
    @IBOutlet weak var uploadFriendlyGames: NSButton!
    @IBOutlet weak var uploadAdventureGames: NSButton!
    @IBOutlet weak var uploadSpectatorGames: NSButton!
    
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
        
        showPushNotification.state = settings.showHSReplayPushNotification ? NSOnState : NSOffState
        synchronizeMatches.state = settings.hsReplaySynchronizeMatches ? NSOnState : NSOffState
        
        // swiftlint:disable line_length
        uploadRankedGames.state = settings.hsReplayUploadRankedMatches ? NSOnState : NSOffState
        uploadCasualGames.state = settings.hsReplayUploadCasualMatches ? NSOnState : NSOffState
        uploadArenaGames.state = settings.hsReplayUploadArenaMatches ? NSOnState : NSOffState
        uploadBrawlGames.state = settings.hsReplayUploadBrawlMatches ? NSOnState : NSOffState
        uploadFriendlyGames.state = settings.hsReplayUploadFriendlyMatches ? NSOnState : NSOffState
        uploadAdventureGames.state = settings.hsReplayUploadAdventureMatches ? NSOnState : NSOffState
        uploadSpectatorGames.state = settings.hsReplayUploadSpectatorMatches ? NSOnState : NSOffState
        // swiftlint:enable line_length
        
        updateUploadGameTypeView()
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
        } else if sender == uploadRankedGames {
            settings.hsReplayUploadRankedMatches = uploadRankedGames.state == NSOnState
        } else if sender == uploadCasualGames {
            settings.hsReplayUploadCasualMatches = uploadCasualGames.state == NSOnState
        } else if sender == uploadArenaGames {
            settings.hsReplayUploadArenaMatches = uploadArenaGames.state == NSOnState
        } else if sender == uploadBrawlGames {
            settings.hsReplayUploadBrawlMatches = uploadBrawlGames.state == NSOnState
        } else if sender == uploadFriendlyGames {
            settings.hsReplayUploadFriendlyMatches = uploadFriendlyGames.state == NSOnState
        } else if sender == uploadAdventureGames {
            settings.hsReplayUploadAdventureMatches = uploadAdventureGames.state == NSOnState
        } else if sender == uploadSpectatorGames {
            settings.hsReplayUploadSpectatorMatches = uploadSpectatorGames.state == NSOnState
        }
        
        updateUploadGameTypeView()
    }
    
    fileprivate func updateUploadGameTypeView() {
        if synchronizeMatches.state == NSOffState {
            uploadRankedGames.isEnabled = false
            uploadCasualGames.isEnabled = false
            uploadArenaGames.isEnabled = false
            uploadBrawlGames.isEnabled = false
            uploadFriendlyGames.isEnabled = false
            uploadAdventureGames.isEnabled = false
            uploadSpectatorGames.isEnabled = false
        } else {
            uploadRankedGames.isEnabled = true
            uploadCasualGames.isEnabled = true
            uploadArenaGames.isEnabled = true
            uploadBrawlGames.isEnabled = true
            uploadFriendlyGames.isEnabled = true
            uploadAdventureGames.isEnabled = true
            uploadSpectatorGames.isEnabled = true
        }
    }
    
    @IBAction func disconnectAccount(_ sender: AnyObject) {
        Settings.instance.hsReplayUsername = nil
        Settings.instance.hsReplayId = nil
        updateStatus()
    }
    
    @IBAction func resetAccount(_ sender: Any) {
        Settings.instance.hsReplayUsername = nil
        Settings.instance.hsReplayId = nil
        Settings.instance.hsReplayUploadToken = nil
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
        
        HSReplayAPI.updateAccountStatus { (status) in
            self.requests += 1
            if status {
                self.getAccountTimer?.invalidate()
            }
            self.updateStatus()
        }
    }
    
    private func updateStatus() {
        if let _ = Settings.instance.hsReplayId {
            var information = NSLocalizedString("Connected", comment: "")
            if let username = Settings.instance.hsReplayUsername {
                information = String(format: NSLocalizedString("Connected as %@", comment: ""),
                                     username)
            }
            hsReplayAccountStatus.stringValue = information
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
