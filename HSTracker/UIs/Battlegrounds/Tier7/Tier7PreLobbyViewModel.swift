//
//  Tier7PreLobbyViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/8/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

enum UserState: Int {
    case loading, unknownPlayer, validPlayer, subscribed, disabled
}

enum RefreshSubscriptionState: Int {
    case hidden, signIn, refresh
}

class Tier7PreLobbyViewModel: ViewModel {
    
    override init() {
        super.init()
        // FIXME: notifications
    }
    
    var battlegroundsGameMode: SelectedBattlegroundsGameMode {
        get {
            return getProp(.unknown)
        }
        set {
            setProp(newValue)
        }
    }
    
    var visibility: Bool {
        get {
            return getProp(false)
        }
        set {
            setProp(newValue)
        }
    }
    
    var userState: UserState {
        get {
            if RemoteConfig.data?.tier7?.disabled ?? false {
                return .disabled
            }
            return getProp(.loading)
        }
        set {
            setProp(newValue)
        }
    }
    
    var refreshSubscriptionState: RefreshSubscriptionState {
        get {
            return getProp(.hidden)
        }
        set {
            setProp(newValue)
        }
    }
    
    var trialUsesRemaining: Int? {
        get {
            return getProp(nil)
        }
        set {
            setProp(newValue)
        }
    }
    
    var allTimeHighMMR: String? {
        get {
            return getProp(nil)
        }
        set {
            setProp(newValue)
        }
    }
    
    var allTimeHighMMRVisibility: Bool {
        get {
            return getProp(false)
        }
        set {
            setProp(newValue)
        }
    }
    
    var trialTimeRemaining: String? {
        get {
            return getProp(nil)
        }
        set {
            setProp(newValue)
            onPropertyChanged("resetTimeVisibility")
        }
    }
    
    var resetTimeVisibility: Bool {
        return trialTimeRemaining != nil ? true : false
    }
    
    var refreshAccountVisibility: Bool {
        get {
            getProp(false)
        }
        set {
            setProp(newValue)
        }
    }
    
    var refreshAccountEnabled: Bool {
        get {
            getProp(true)
        }
        set {
            setProp(newValue)
        }
    }
    
    var username: String? {
        get {
            getProp(nil)
        }
        set {
            setProp(newValue)
        }
    }
    
    private var _isUpdatingAccount = false
    
    @available(macOS 10.15.0, *)
    func update(_ checkAccountStatus: Bool) async {
        if userState == .disabled {
            return
        }
        if _isUpdatingAccount {
            // AccountDataUpdated event was likely trigger by the
            // UpdateAccountData request below. SKip this update
            return
        }
        if AppDelegate.instance().coreManager.game.currentMode != .bacon {
            return
        }
        
        if await Debounce.wasCalledAgain(milliseconds: 50) {
            // Debounce to avoid multiple invocations of this when the log
            // is being (re-)read and contains multiple scene changes in
            // and out of BACON.
            return
        }
        
        var ownsTier7 = false
        if HSReplayAPI.isFullyAuthenticated && HSReplayAPI.accountData != nil {
            if checkAccountStatus {
                // This will fire a HSReplayNetOAuth.AccountDataUpdated event. We
                // set a flag for the duration of the update check to avoid
                // infinite recursion here.
                _isUpdatingAccount = true
                // (Unrelativ to the event) If we want to cut down the request
                // volume here in the future we can only make this request for
                // tier7 subscribers (still need to happen right here, not below to
                // handle the case where tier7 ran out).
                _ = await HSReplayAPI.getAccountAsync()
                _isUpdatingAccount = false
            }
            isAuthenticated = true
            ownsTier7 = HSReplayAPI.accountData?.is_tier7 ?? false
            
            // Update the Refresh button, as it's otherwise only updated after a click on GET PREMIUM
            if ownsTier7 {
                refreshSubscriptionState = .hidden
            } else if refreshSubscriptionState == .signIn {
                refreshSubscriptionState = .refresh
            }
        } else {
            isAuthenticated = false
            if refreshSubscriptionState == .refresh {
                refreshSubscriptionState = .signIn
            }
        }
        
        let acc = MirrorHelper.getAccountId()
        username = MirrorHelper.getBattleTag()?.components(separatedBy: "#")[0] ?? HSReplayAPI.accountData?.username ?? nil
        if !ownsTier7 {
            allTimeHighMMR = nil
            guard let acc = acc else {
                // unable to get AccountHi/AccountLo, not eligible for trials
                userState = .unknownPlayer
                return
            }
            await Tier7Trial.update(hi: acc.hi.int64Value, lo: acc.lo.int64Value)
            trialTimeRemaining = Tier7Trial.timeRemaining
            trialUsesRemaining = Tier7Trial.remainingTrials ?? 0
            userState = .validPlayer
            return
        }
        
        if userState != .subscribed {
            userState = .loading
        }
        
        trialTimeRemaining = nil
        var allTimeFromApi: Int?
        
        if let acc = acc {
            allTimeFromApi = await HSReplayAPI.getAllTimeBGsMMR(hi: acc.hi.int64Value, lo: acc.lo.intValue)?.all_time_high_mmr
        }
        let currentMMR = AppDelegate.instance().coreManager.game.battlegroundsRatingInfo?.rating.intValue
        if let api = allTimeFromApi, let curr = currentMMR {
            allTimeHighMMR = "\(max(api, curr))"
        } else if let api = allTimeFromApi {
            allTimeHighMMR = "\(api)"
        } else if let curr = currentMMR {
            allTimeHighMMR = "\(curr)"
        } else {
            allTimeHighMMR = nil
        }
        allTimeHighMMRVisibility = allTimeHighMMR != nil
        userState = .subscribed
    }
    
    var isAuthenticated = false
    
    func reset() {
        userState = .loading
        allTimeHighMMR = nil
        trialTimeRemaining = nil
        username = nil
    }
}
