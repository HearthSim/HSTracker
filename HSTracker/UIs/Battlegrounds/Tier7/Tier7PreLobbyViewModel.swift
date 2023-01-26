//
//  Tier7PreLobbyViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/8/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

enum UserState: Int {
    case loading, anonymous, authenticated, subscribed
}

class Tier7PreLobbyViewModel: ViewModel {
    
    override init() {
        super.init()
        // FIXME: notifications
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
            return getProp(.loading)
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
        
        if !HSReplayAPI.isFullyAuthenticated || HSReplayAPI.accountData == nil {
            userState = .anonymous
            allTimeHighMMR = nil
            trialTimeRemaining = nil
            username = nil
        }
        
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
        
        if !(HSReplayAPI.accountData?.is_tier7 ?? false) {
            if userState != .authenticated {
                userState = .loading
            }
            allTimeHighMMR = nil
            await Tier7Trial.update()
            trialTimeRemaining = Tier7Trial.timeRemaining
            trialUsesRemaining = Tier7Trial.remainingTrials ?? 0
            username = MirrorHelper.getBattleTag()?.components(separatedBy: "#")[0] ?? HSReplayAPI.accountData?.username
            userState = .authenticated
            return
        }
        
        if userState != .subscribed {
            userState = .loading
            username = MirrorHelper.getBattleTag()?.components(separatedBy: "#")[0] ?? HSReplayAPI.accountData?.username
        }
        
        trialTimeRemaining = nil
        var allTimeFromApi: Int?
        
        if let acc = MirrorHelper.getAccountId() {
            allTimeFromApi = await HSReplayAPI.getAllTimeBGsMMR(hi: acc.hi.int64Value, lo: acc.lo.intValue)?.all_time_high_mmr
        }
        let currentMMR = AppDelegate.instance().coreManager.game.battlegroundsRating
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
    
    func reset() {
        userState = .loading
        allTimeHighMMR = nil
        trialTimeRemaining = nil
        username = nil
    }
}
