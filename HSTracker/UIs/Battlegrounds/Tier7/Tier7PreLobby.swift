//
//  Tier7PreLobby.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/9/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation
import Preferences

class Tier7PreLobby: OverWindowController {
    
    @IBOutlet weak var anonymousHover: NSBox!
    @IBOutlet weak var loading: NSStackView!
    @IBOutlet weak var anonymous: NSStackView!
    @IBOutlet weak var authenticated: NSStackView!
    @IBOutlet weak var subscribed: NSStackView!
    @IBOutlet weak var disabled: NSView!
    @IBOutlet weak var welcomeLabel: NSTextField!
    @IBOutlet weak var trialsRemainingLabel: NSTextField!
    @IBOutlet weak var trialTimeRemainingLabel: NSTextField!
    @IBOutlet weak var refreshAccount: NSStackView!
    @IBOutlet weak var refreshButton: NSButton!
    @IBOutlet weak var subscribedView: NSStackView!
    @IBOutlet weak var signInButton: NSButton!
    @IBOutlet weak var allTimeHighMMR: NSTextField!
    
    @IBOutlet weak var informationLabel: NSTextField!
    
    var viewModel = Tier7PreLobbyViewModel()
    
    override var alwaysLocked: Bool {
        return true
    }
    
    override func updateFrames() {
    }
    
    override func awakeFromNib() {
        viewModel.propertyChanged = { name in
            DispatchQueue.main.async {
                self.update(name)
            }
        }
        let trackingArea = NSTrackingArea(rect: NSRect.zero,
                                          options: [NSTrackingArea.Options.inVisibleRect, NSTrackingArea.Options.activeAlways, NSTrackingArea.Options.mouseEnteredAndExited],
                                          owner: self,
                                          userInfo: nil)
        anonymous.addTrackingArea(trackingArea)
        refreshButton.underlined()
        informationLabel.addCustomToolTip(from: informationLabel.toolTip ?? "")
        informationLabel.toolTip = nil
        informationLabel.updateTrackingAreas_CustomToolTip()
        update(nil)
    }
    
    override func mouseEntered(with event: NSEvent) {
        if viewModel.userState == .unknownPlayer {
            anonymousHover.isHidden = false
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        anonymousHover.isHidden = true
    }
    
    private func update(_ property: String?) {
        let all = property == nil
        if property == "userState" || all {
            let userState = viewModel.userState
            anonymous.isHidden = userState != .unknownPlayer
            loading.isHidden = userState != .loading
            authenticated.isHidden = userState != .validPlayer
            subscribed.isHidden = userState != .subscribed
            disabled.isHidden = userState != .disabled
        }
        if property == "refreshSubscriptionState" || all {
            subscribedView.isHidden = viewModel.refreshSubscriptionState != .signIn
        }
        if property == "allTimeHighMMR" || all {
            allTimeHighMMR.stringValue = viewModel.allTimeHighMMR ?? ""
        }
        if property == "allTimeHighMMRVisibility" || all {
            allTimeHighMMR.isHidden = !viewModel.allTimeHighMMRVisibility
        }
        if property == "username" || all {
            welcomeLabel.stringValue = String(format: String.localizedString("BattlegroundsPreLobby_Authenticated_Welcome", comment: ""), viewModel.username ?? "")
        }
        
        if property == "trialUsesRemaining" || all {
            trialsRemainingLabel.stringValue = String(format: String.localizedString("BattlegroundsPreLobby_Authenticated_TrialsRemaining", comment: ""), viewModel.trialUsesRemaining ?? 0)
        }
        
        if property == "resetTimeVisibility" || all {
            trialTimeRemainingLabel.isHidden = !viewModel.resetTimeVisibility
        }
        
        if property == "trialTimeRemaining" || all {
            trialTimeRemainingLabel.stringValue = String(format: String.localizedString("BattlegroundsPreLobby_Authenticated_TrialsResetsIn", comment: ""), viewModel.trialTimeRemaining ?? "")
        }
        
        if property == "refreshAccountVisibility" || all {
            refreshAccount.isHidden = !viewModel.refreshAccountVisibility
        }
        
        if property == "refreshAccountEnabled" || all {
            refreshButton.isEnabled = viewModel.refreshAccountEnabled
        }
    }
    
    @IBAction func signCommand(_ sender: AnyObject) {
        AppDelegate.instance().openPreferences(pane: Preferences.PaneIdentifier.hsreplay)
    }
    
    @IBAction func myStatsCommand(_ sender: AnyObject) {
        let acc = MirrorHelper.getAccountId()
        let url = "https://hsreplay.net/battlegrounds/mine/?utm_source=hstracker&utm_medium=client&utm_campaign=bgs_lobby_my_stats&hearthstone_account=\(acc?.hi ?? 0)-\(acc?.lo ?? 0)"

        NSWorkspace.shared.open(URL(string: url)!)
    }
    
    @IBAction func subscribeNowCommand(_ sender: AnyObject) {
        let url = "https://hsreplay.net/battlegrounds/tier7/?utm_source=hstracker&utm_medium=client&utm_campaign=bgs_lobby_subscribe"

        NSWorkspace.shared.open(URL(string: url)!)
        viewModel.refreshSubscriptionState = viewModel.isAuthenticated ? .refresh : .signIn
    }
    
    @IBAction func refreshAccountCommand(_ sender: AnyObject) {
        if #available(macOS 10.15, *) {
            Task.init {
                viewModel.refreshAccountEnabled = false
                viewModel.invalidateUserState()
                await withThrowingTaskGroup(of: Void.self, body: { group in
                    group.addTask {
                        _ = await HSReplayAPI.getAccountAsync()
                    }
                    group.addTask {
                        try await Task.sleep(nanoseconds: 3_000_000_000)
                    }
                })
                viewModel.refreshAccountEnabled = true
            }
        }
    }
}
