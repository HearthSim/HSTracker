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
            onPropertyChanged("allTimeHighMMRVisibility")
        }
    }
    
    var isModalOpen: Bool {
        get {
            return getProp(false)
        }
        set {
            setProp(newValue)
            onPropertyChanged("visibility")
        }
    }
    
    var visibility: Bool {
        return isModalOpen ? false : true
    }
    
    func invalidateUserState() {
        userState = .loading
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
    
    func onFocus() {
        possiblySubscribed = true
    }
    
    var possiblySubscribed: Bool {
        get {
            return getProp(false)
        }
        set {
            setProp(newValue)
            onPropertyChanged("refreshSubscriptionState")
        }
    }
    
    var refreshSubscriptionState: RefreshSubscriptionState {
        if (trialUsesRemaining ?? 0 > 0 && !possiblySubscribed) || isAuthenticated == nil {
            return .hidden
        }
        return isAuthenticated == true ? .refresh : .signIn
    }
    
    var trialUsesRemaining: Int? {
        get {
            return getProp(nil)
        }
        set {
            setProp(newValue)
            onPropertyChanged("refreshSubscriptionState")
        }
    }
    
    var allTimeHighMMR: String? {
        get {
            return getProp(nil)
        }
        set {
            setProp(newValue)
            onPropertyChanged("allTimeHighMMRVisibility")
        }
    }
    
    var allTimeHighMMRVisibility: Bool {
        if allTimeHighMMR == nil || battlegroundsGameMode != .solo {
            return false
        }
        return true
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
    func update() async {
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
            if userState == .loading {
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
        } else {
            isAuthenticated = false
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
        userState = .subscribed
    }
    
    var isAuthenticated: Bool? {
        get {
            return getProp(nil)
        }
        set {
            setProp(newValue)
            onPropertyChanged("refreshSubscriptionState")
        }
    }
    
    func reset() {
        userState = .loading
        allTimeHighMMR = nil
        trialTimeRemaining = nil
        username = nil
    }
}
