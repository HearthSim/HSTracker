//
//  HSReplayPreferences.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 13/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Preferences

class HSReplayPreferences: NSViewController, PreferencePane {
    var preferencePaneIdentifier = Preferences.PaneIdentifier.hsreplay
    
    var preferencePaneTitle = "HSReplay"
    
    var toolbarItemIcon = NSImage(named: "hsreplay_logo_white")!
    
    @IBOutlet var synchronizeMatches: NSButton!
    @IBOutlet var gameTypeSelector: NSView!
    @IBOutlet var uploadRankedGames: NSButton!
    @IBOutlet var uploadCasualGames: NSButton!
    @IBOutlet var uploadArenaGames: NSButton!
    @IBOutlet var uploadBrawlGames: NSButton!
    @IBOutlet var uploadFriendlyGames: NSButton!
    @IBOutlet var uploadAdventureGames: NSButton!
    @IBOutlet var uploadSpectatorGames: NSButton!
    @IBOutlet var uploadBattlegroundsGames: NSButton!
    @IBOutlet var uploadDuelsGames: NSButton!
    @IBOutlet var uploadMercenariesGames: NSButton!

    @IBOutlet var showPushNotification: NSButton!
    @IBOutlet var oAuthAccount: NSButton!
    @IBOutlet var myAccountMessage: NSTextField!
    private var getAccountTimer: Timer?
    private var requests = 0
    private let maxRequests = 10
    
    @objc dynamic var statusIcon = ""
    @objc dynamic var statusColor = NSColor.red

    override func viewWillAppear() {
        super.viewWillAppear()

        showPushNotification.state = Settings.showHSReplayPushNotification ? .on : .off
        synchronizeMatches.state = Settings.hsReplaySynchronizeMatches ? .on : .off

        uploadRankedGames.state = Settings.hsReplayUploadRankedMatches ? .on : .off
        uploadCasualGames.state = Settings.hsReplayUploadCasualMatches ? .on : .off
        uploadArenaGames.state = Settings.hsReplayUploadArenaMatches ? .on : .off
        uploadBrawlGames.state = Settings.hsReplayUploadBrawlMatches ? .on : .off
        uploadFriendlyGames.state = Settings.hsReplayUploadFriendlyMatches ? .on : .off
        uploadAdventureGames.state = Settings.hsReplayUploadAdventureMatches ? .on : .off
        uploadSpectatorGames.state = Settings.hsReplayUploadSpectatorMatches ? .on : .off
        uploadBattlegroundsGames.state = Settings.hsReplayUploadBattlegroundsMatches ? .on : .off
        uploadDuelsGames.state = Settings.hsReplayUploadDuelsMatches ? .on : .off
        uploadMercenariesGames.state = Settings.hsReplayUploadMercenariesMatches ? .on : .off

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
        } else if sender == uploadBattlegroundsGames {
            Settings.hsReplayUploadBattlegroundsMatches = uploadBattlegroundsGames.state == .on
        } else if sender == uploadDuelsGames {
            Settings.hsReplayUploadDuelsMatches = uploadDuelsGames.state == .on
        } else if sender == uploadMercenariesGames {
            Settings.hsReplayUploadMercenariesMatches = uploadMercenariesGames.state == .on
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
            uploadBattlegroundsGames.isEnabled = false
            uploadDuelsGames.isEnabled = false
            uploadMercenariesGames.isEnabled = false
        } else {
            uploadRankedGames.isEnabled = true
            uploadCasualGames.isEnabled = true
            uploadArenaGames.isEnabled = true
            uploadBrawlGames.isEnabled = true
            uploadFriendlyGames.isEnabled = true
            uploadAdventureGames.isEnabled = true
            uploadSpectatorGames.isEnabled = true
            uploadBattlegroundsGames.isEnabled = true
            uploadDuelsGames.isEnabled = true
            uploadMercenariesGames.isEnabled = true
        }
    }

    @IBAction func oauthAccount(_ sender: AnyObject) {
        if Settings.hsReplayOAuthRefreshToken != nil {
            Settings.hsReplayOAuthRefreshToken = nil
            Settings.hsReplayOAuthToken = nil
            Settings.hsReplayUploadToken = nil
            Settings.hsReplayUsername = nil
            MixpanelEvents.resetAccount()

            updateStatus()
        } else {
            HSReplayAPI.oAuthAuthorize {
                HSReplayAPI.linkMixpanelAccount()
                _ = HSReplayAPI.getAccount().done { result in
                    switch result {
                    case .failed:
                        logger.error("Failed to retrieve account data")
                    case .success(account: let data):
                        Settings.hsReplayUsername = data.username
                        logger.info("Successfully retrieved account data: Username: \(data.username), battletag: \(data.battletag)")
                    }

                    self.updateStatus()
                }
            }
        }
    }

    @objc private func checkAccountInfo() {
        guard requests < maxRequests else {
            logger.warning("max request for checking account info")
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
        if Settings.hsReplayOAuthRefreshToken != nil {
            oAuthAccount.title = String.localizedString("Logout", comment: "")
            var message = String.localizedString("Logged in to HSReplay.net. Open your collection and it will be automatically uploaded.", comment: "")

            if let username = Settings.hsReplayUsername {
                message = String(format: String.localizedString("Logged in to HSReplay.net as %@. Open your collection and it will be automatically uploaded.", comment: ""), username)
            }
            myAccountMessage.stringValue = message
        } else {
            oAuthAccount.title = String.localizedString("Login to HSReplay.net", comment: "")
            myAccountMessage.stringValue = String.localizedString("Login to claim your replays and enable all HSReplay.net features.", comment: "")
        }
        
        statusIcon = hasSubscription ? "✔" : "✖"
        statusColor = hasSubscription ? NSColor.green : NSColor.red
    }
    
    @objc dynamic var hasSubscription: Bool {
        return subscriptions != SubscriptionStatus.none
    }
    
    @objc dynamic var subscriptionStatusText: String {
        return switch subscriptions {
        case .premium:
            String.localizedString("Options_HSReplay_Account_Subscription_Premium", comment: "")
        case .tier7:
            String.localizedString("Options_HSReplay_Account_Subscription_Tier7", comment: "")
        case .bundle:
            String.localizedString("Options_HSReplay_Account_Subscription_Bundle", comment: "")
        default:
            String.localizedString("Options_HSReplay_Account_Subscription_Generic", comment: "")
        }
    }
    
    var subscriptions: SubscriptionStatus {
        let isPremium = HSReplayAPI.accountData?.is_premium ?? false
        let isTier7 = HSReplayAPI.accountData?.is_tier7 ?? false
            
        if isPremium && isTier7 {
            return .bundle
        }
        if isPremium {
            return .premium
        }
        if isTier7 {
            return .tier7
        }
        return .none
    }
}

enum SubscriptionStatus {
    case none, premium, tier7, bundle
}

// MARK: - Preferences
extension Preferences.PaneIdentifier {
    static let hsreplay = Self("hsreplay")
}
