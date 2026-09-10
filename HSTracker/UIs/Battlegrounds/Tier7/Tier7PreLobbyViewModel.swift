//
//  Tier7PreLobbyViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/8/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation
import AppKit
import Preferences

// Not gated on the SwiftUI baseline: ConstructedMulliganPreLobbyWidgetViewModel
// reuses both of these as-is, the same way HDT's own Constructed widget reuses
// them from its Tier7 equivalent.
enum UserState: Int {
    case loading, unknownPlayer, validPlayer, subscribed, disabled
}

enum RefreshSubscriptionState: Int {
    case hidden, signIn, refresh
}

// Port of HDT's Tier7PreLobbyViewModel
// (Controls/Overlay/Battlegrounds/Tier7/Tier7PreLobbyViewModel.cs).
@available(macOS 10.15, *)
class Tier7PreLobbyViewModel: ObservableObject {
    // HDT drives this panel's presence with _tier7PreLobbyBehavior.Show()/Hide()
    // rather than a view-model flag; on the RootOverlay canvas there is no
    // window to show or hide, so Game.updateTier7PreLobbyVisibility() sets this
    // instead - same role isShown plays on the Constructed pre-lobby widget.
    @Published var isShown = false
    @Published var battlegroundsGameMode: SelectedBattlegroundsGameMode = .unknown
    // HDT: IsGameCriticalUiOpen.
    @Published var isModalOpen = false
    @Published private var _userState: UserState = .loading
    @Published var trialUsesRemaining: Int?
    @Published var trialTimeRemaining: String?
    @Published var allTimeHighMMR: String?
    @Published var isAuthenticated: Bool?
    @Published var username: String?
    @Published var refreshAccountEnabled = true
    @Published var isCollapsed: Bool
    @Published private var possiblySubscribed = false

    private var _isUpdatingAccount = false

    init() {
        isCollapsed = Settings.tier7OverlayCollapsed
    }

    var visibility: Bool {
        !isModalOpen
    }

    var userState: UserState {
        get {
            if RemoteConfig.data?.tier7?.disabled ?? false {
                return .disabled
            }
            return _userState
        }
        set {
            _userState = newValue
        }
    }

    func invalidateUserState() {
        userState = .loading
    }

    func onFocus() {
        possiblySubscribed = true
    }

    var refreshSubscriptionState: RefreshSubscriptionState {
        if ((trialUsesRemaining ?? 0) > 0 && !possiblySubscribed) || isAuthenticated == nil {
            return .hidden
        }
        return isAuthenticated == true ? .refresh : .signIn
    }

    var allTimeHighMMRVisibility: Bool {
        if allTimeHighMMR == nil || battlegroundsGameMode != .solo {
            return false
        }
        return true
    }

    var resetTimeVisibility: Bool {
        trialTimeRemaining != nil
    }

    // HDT's PanelMinWidth: the two states with a 230-wide content column get a
    // wider panel than the two with a 182-wide one.
    var panelMinWidth: CGFloat {
        userState == .validPlayer || userState == .subscribed ? 264 : 214
    }

    // RemoteConfig.data is fetched once at app launch and never live-updated
    // afterward (see RemoteConfig.checkRemoteConfig), so a plain synchronous
    // read here - the same pattern userState's tier7?.disabled check above
    // uses - stands in for HDT's Remote.Config.Loaded subscription.
    private var saleData: SaleData? {
        RemoteConfig.data?.sales?.battlegrounds
    }

    var saleTagVisibility: Bool {
        saleData?.enabled ?? false
    }

    var saleTooltipVisibility: Bool {
        guard let saleData, saleData.enabled else {
            return false
        }
        return Settings.ignoreBattlegroundsSaleId < saleData.id
    }

    var saleDescription: String {
        guard let saleData, saleData.enabled else {
            return ""
        }
        return String(format: String.localizedString("BattlegroundsPreLobby_SaleTooltip_Description", comment: ""), saleData.discount)
    }

    func toggleCollapsed() {
        isCollapsed.toggle()
        Settings.tier7OverlayCollapsed = isCollapsed
    }

    func closeSaleTooltip() {
        Settings.ignoreBattlegroundsSaleId = saleData?.id ?? -1
        // saleTooltipVisibility is a plain computed property (not its own
        // @Published), so nothing would otherwise tell SwiftUI to re-read it
        // after this write.
        objectWillChange.send()
    }

    func showSettings() {
        AppDelegate.instance().openPreferences(pane: Preferences.PaneIdentifier.battlegrounds)
    }

    func signIn() {
        AppDelegate.instance().openPreferences(pane: Preferences.PaneIdentifier.hsreplay)
    }

    func subscribeNow() {
        let url = Helper.buildHsReplayNetUrl("battlegrounds/tier7/", "bgs_lobby_subscribe")
        if let url = URL(string: url) {
            NSWorkspace.shared.open(url)
        }
        possiblySubscribed = true
    }

    func myStats() {
        let acc = MirrorHelper.getAccountId()
        var queryParams: [String]?
        if let acc {
            queryParams = ["hearthstone_account=\(acc.hi)-\(acc.lo)"]
        }
        let url = Helper.buildHsReplayNetUrl("battlegrounds/mine/", "bgs_lobby_my_stats", queryParams)
        if let url = URL(string: url) {
            NSWorkspace.shared.open(url)
        }
    }

    func refreshAccount() {
        Task.detached { [weak self] in
            guard let self else { return }
            await MainActor.run {
                self.refreshAccountEnabled = false
                self.invalidateUserState()
            }
            async let accountUpdate: GetAccountResult = HSReplayAPI.getAccountAsync()
            async let delay: Void = { try? await Task.sleep(nanoseconds: 3_000_000_000) }()
            _ = await (accountUpdate, delay)
            await self.update()
            await MainActor.run {
                self.refreshAccountEnabled = true
            }
        }
    }

    @MainActor
    func update() async {
        if userState == .disabled {
            return
        }
        // HDT guards on the game mode the lobby watcher reports, not on
        // game.currentMode. currentMode only becomes .bacon once the log
        // readers have replayed the LoadingScreen line announcing the scene,
        // which lands roughly half a second after the memory mirror has
        // already told SceneHandler we are in BACON. Launching HSTracker while
        // Hearthstone sits in the Battlegrounds lobby therefore ran this
        // update while currentMode was still .invalid: it returned without
        // ever setting userState, and with nothing in the lobby changing
        // afterwards nothing called back in, so the widget sat on its loading
        // spinner for the rest of the session.
        if battlegroundsGameMode == .unknown {
            return
        }
        if _isUpdatingAccount {
            // AccountDataUpdated event was likely triggered by the
            // UpdateAccountData request below. Skip this update.
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
        username = MirrorHelper.getBattleTag()?.components(separatedBy: "#").first ?? HSReplayAPI.accountData?.username

        if !ownsTier7 {
            allTimeHighMMR = nil
            guard let acc else {
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

        if let acc {
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

    func reset() {
        userState = .loading
        allTimeHighMMR = nil
        trialTimeRemaining = nil
        username = nil
        battlegroundsGameMode = .unknown
    }
}
