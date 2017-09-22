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

        showPushNotification.state = Settings.showHSReplayPushNotification ? .on : .off
        synchronizeMatches.state = Settings.hsReplaySynchronizeMatches ? .on : .off
        
        // swiftlint:disable line_length
        uploadRankedGames.state = Settings.hsReplayUploadRankedMatches ? .on : .off
        uploadCasualGames.state = Settings.hsReplayUploadCasualMatches ? .on : .off
        uploadArenaGames.state = Settings.hsReplayUploadArenaMatches ? .on : .off
        uploadBrawlGames.state = Settings.hsReplayUploadBrawlMatches ? .on : .off
        uploadFriendlyGames.state = Settings.hsReplayUploadFriendlyMatches ? .on : .off
        uploadAdventureGames.state = Settings.hsReplayUploadAdventureMatches ? .on : .off
        uploadSpectatorGames.state = Settings.hsReplayUploadSpectatorMatches ? .on : .off
        // swiftlint:enable line_length
        
        updateUploadGameTypeView()
        updateStatus()
    }
    
    override func viewDidDisappear() {
        getAccountTimer?.invalidate()
    }
    
    @IBAction func checkboxClicked(_ sender: NSButton) {
        if sender == synchronizeMatches {
            Settings.hsReplaySynchronizeMatches = synchronizeMatches.state == .on
        } else if sender == showPushNotification {
            Settings.showHSReplayPushNotification = showPushNotification.state == .on
        } else if sender == uploadRankedGames {
            Settings.hsReplayUploadRankedMatches = uploadRankedGames.state == .on
        } else if sender == uploadCasualGames {
            Settings.hsReplayUploadCasualMatches = uploadCasualGames.state == .on
        } else if sender == uploadArenaGames {
            Settings.hsReplayUploadArenaMatches = uploadArenaGames.state == .on
        } else if sender == uploadBrawlGames {
            Settings.hsReplayUploadBrawlMatches = uploadBrawlGames.state == .on
        } else if sender == uploadFriendlyGames {
            Settings.hsReplayUploadFriendlyMatches = uploadFriendlyGames.state == .on
        } else if sender == uploadAdventureGames {
            Settings.hsReplayUploadAdventureMatches = uploadAdventureGames.state == .on
        } else if sender == uploadSpectatorGames {
            Settings.hsReplayUploadSpectatorMatches = uploadSpectatorGames.state == .on
        }
        
        updateUploadGameTypeView()
    }
    
    fileprivate func updateUploadGameTypeView() {
        if synchronizeMatches.state == .off {
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
        Settings.hsReplayUsername = nil
        Settings.hsReplayId = nil
        updateStatus()
    }
    
    @IBAction func resetAccount(_ sender: Any) {
        Settings.hsReplayUsername = nil
        Settings.hsReplayId = nil
        Settings.hsReplayUploadToken = nil
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
        if Settings.hsReplayId != nil {
            var information = NSLocalizedString("Connected", comment: "")
            if let username = Settings.hsReplayUsername {
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
    var viewIdentifier: String {
        return "hsreplay"
    }
    
    var toolbarItemImage: NSImage? {
        return NSImage(named: NSImage.Name(rawValue: "hsreplay_icon"))
    }
    
    var toolbarItemLabel: String? {
        return "HSReplay"
    }
}
