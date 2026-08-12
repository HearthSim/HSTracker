//
//  ConstructedMulliganPreLobbyWidgetViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/10/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation
import AppKit
import Preferences

// UserState/RefreshSubscriptionState are declared in Tier7PreLobbyViewModel.swift
// and reused here as-is - same shape HDT's own widget reuses from its Tier7
// equivalent.
@available(macOS 10.15, *)
class ConstructedMulliganPreLobbyWidgetViewModel: ObservableObject {
    @Published var visualsFormatType: VisualsFormatType = .vft_unknown {
        didSet {
            showOnboardingNotification = !Settings.mulliganGV2OnboardingSeen && formatType == .ft_standard
            Task.detached { [self] in await self.update() }
        }
    }
    // Whether the widget should be attached to the root overlay at all -
    // driven by Game.swift's menu/tournament-scene gating.
    @Published var isShown = false
    @Published var isModalOpen = false
    @Published var isInQueue = false
    @Published private var _userState: UserState = .loading
    @Published var trialUsesRemaining: Int?
    @Published var trialTimeRemaining: String?
    @Published var isAuthenticated: Bool?
    @Published var username: String?
    @Published var refreshAccountEnabled = true
    @Published var isCollapsed: Bool
    @Published var isOnboardingVisible = false
    @Published var showOnboardingNotification = false
    @Published private var possiblySubscribed = false

    private var _isUpdatingAccount = false

    init() {
        isCollapsed = !Settings.showMulliganGuidePreLobby
    }

    var visibility: Bool {
        !(isModalOpen || isInQueue)
    }

    var userState: UserState {
        get {
            if RemoteConfig.data?.mulligan_guide?.disabled ?? false {
                return .disabled
            }
            return _userState
        }
        set {
            _userState = newValue
        }
    }

    var gameType: BnetGameType {
        switch visualsFormatType {
        case .vft_standard: return .bgt_ranked_standard
        case .vft_wild: return .bgt_ranked_wild
        case .vft_twist: return .bgt_ranked_twist
        case .vft_casual: return .bgt_casual_wild
        default: return .bgt_unknown
        }
    }

    var formatType: FormatType {
        switch visualsFormatType {
        case .vft_standard: return .ft_standard
        case .vft_wild: return .ft_wild
        case .vft_twist: return .ft_twist
        case .vft_casual: return .ft_wild
        default: return .ft_unknown
        }
    }

    var showOnboardingButton: Bool {
        formatType == .ft_standard
    }

    var refreshSubscriptionState: RefreshSubscriptionState {
        if ((trialUsesRemaining ?? 0) > 0 && !possiblySubscribed) || isAuthenticated == nil {
            return .hidden
        }
        return isAuthenticated == true ? .refresh : .signIn
    }

    var panelMinWidth: CGFloat {
        userState == .validPlayer || userState == .subscribed ? 264 : 214
    }

    var resetTimeVisibility: Bool {
        trialTimeRemaining != nil
    }

    // RemoteConfig.data is fetched once at app launch and never live-updated
    // afterward (see RemoteConfig.checkRemoteConfig), so a plain synchronous
    // read here - same pattern as userState's mulligan_guide?.disabled check
    // above - is enough; no separate "config changed" subscription needed.
    private var saleData: SaleData? {
        RemoteConfig.data?.sales?.traditional
    }

    var saleTagVisibility: Bool {
        saleData?.enabled ?? false
    }

    var saleTooltipVisibility: Bool {
        guard !showOnboardingNotification, let saleData, saleData.enabled else {
            return false
        }
        return Settings.ignoreTraditionalSaleId < saleData.id
    }

    var saleDescription: String {
        guard let saleData, saleData.enabled else {
            return ""
        }
        // Matches HDT: the traditional (non-Battlegrounds) pre-lobby surfaces
        // (Constructed, Arena) share this same loc key.
        return String(format: String.localizedString("TraditionalPreLobby_SaleTooltip_Description", comment: ""), saleData.discount)
    }

    func onFocus() {
        possiblySubscribed = true
    }

    func invalidateUserState() {
        userState = .loading
    }

    func toggleCollapsed() {
        isCollapsed.toggle()
        Settings.showMulliganGuidePreLobby = !isCollapsed
    }

    func toggleOnboarding() {
        isOnboardingVisible.toggle()
        if isOnboardingVisible {
            Settings.mulliganGV2OnboardingSeen = true
        }
    }

    func dismissOnboardingNotification() {
        showOnboardingNotification = false
        Settings.mulliganGV2OnboardingSeen = true
    }

    func learnMoreOnboarding() {
        isOnboardingVisible = true
        showOnboardingNotification = false
    }

    func closeSaleTooltip() {
        Settings.ignoreTraditionalSaleId = saleData?.id ?? -1
        // saleTooltipVisibility is a plain computed property (not its own
        // @Published), so nothing would otherwise tell SwiftUI to re-read it
        // after this write.
        objectWillChange.send()
    }

    func subscribeNow() {
        let campaign = formatType == .ft_standard ? "constructed_lobby_subscribe" : "constructed_lobby_subscribe_wild"
        let url = Helper.buildHsReplayNetUrl("premium/", campaign)
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
        let url = Helper.buildHsReplayNetUrl("decks/mine/", "constructed_lobby_my_stats", queryParams)
        if let url = URL(string: url) {
            NSWorkspace.shared.open(url)
        }
    }

    func signIn() {
        AppDelegate.instance().openPreferences(pane: Preferences.PaneIdentifier.hsreplay)
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
        if formatType == .ft_unknown || formatType == .ft_twist || formatType == .ft_classic {
            return
        }
        if visualsFormatType == .vft_casual {
            return
        }
        if _isUpdatingAccount {
            return
        }

        var ownsPremium = false
        if HSReplayAPI.isFullyAuthenticated && HSReplayAPI.accountData != nil {
            if userState == .loading {
                _isUpdatingAccount = true
                _ = await HSReplayAPI.getAccountAsync()
                _isUpdatingAccount = false
            }
            isAuthenticated = true
            ownsPremium = HSReplayAPI.accountData?.is_premium ?? false
        } else {
            isAuthenticated = false
        }

        let acc = MirrorHelper.getAccountId()
        username = MirrorHelper.getBattleTag()?.components(separatedBy: "#").first ?? HSReplayAPI.accountData?.username

        if !ownsPremium {
            guard let acc else {
                userState = .unknownPlayer
                return
            }
            await MulliganGuideTrial.update(hi: acc.hi.int64Value, lo: acc.lo.int64Value)
            trialTimeRemaining = MulliganGuideTrial.timeRemaining
            trialUsesRemaining = MulliganGuideTrial.remainingTrials ?? 0
            userState = .validPlayer
            return
        }

        trialTimeRemaining = nil
        userState = .subscribed
    }

    func reset() {
        isShown = false
        isModalOpen = false
        isInQueue = false
        userState = .loading
        trialTimeRemaining = nil
        username = nil
        visualsFormatType = .vft_unknown
    }
}
