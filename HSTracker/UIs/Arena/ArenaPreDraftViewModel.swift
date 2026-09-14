//
//  ArenaPreDraftViewModel.swift
//  HSTracker
//
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation
import SwiftUI
import Preferences

/// Where the player is relative to starting a draft. Only the first two put the
/// panel on screen.
enum ArenaDraftState {
    case other
    /// On the landing screen with no run in progress - one click from drafting.
    case preDraft
    /// On the landing screen with a run already going.
    case midDraft
}

enum ArenasmithAvailability {
    case loading
    case available
    case unavailable
}

enum ArenaUserState {
    case loading
    case unknownPlayer
    case trialPlayer
    case subscriber
    case invalidated
}

enum ArenaRefreshSubscriptionState {
    case hidden
    case signIn
    case refresh
}

/// The panel shown on the Arena landing screen, before a draft starts.
///
/// Port of HDT's `ArenaPreDraftViewModel`. Two independent gates decide what it
/// says: whether HSReplay is serving Arenasmith at all, and what the player's
/// account entitles them to.
@available(macOS 10.15, *)
final class ArenaPreDraftViewModel: ObservableObject {

    @Published private(set) var draftState = ArenaDraftState.other
    @Published private(set) var isUnderground = false
    @Published private(set) var availabilities: ArenasmithAvailabilities?
    @Published private(set) var userState = ArenaUserState.loading
    @Published private(set) var username: String?
    @Published private(set) var starterTrialsRemaining: Int?
    @Published private(set) var recurringTrialsRemaining: Int?
    @Published private(set) var maxTrialUses: Int?
    @Published private(set) var trialTimeRemaining: String?
    @Published private(set) var isTrialEnabledForDeck = false
    @Published private(set) var isAuthenticated: Bool?
    @Published var refreshAccountEnabled = true
    @Published var isCollapsed = Settings.arenasmithPreLobbyTrialsCollapsed

    /// Suppressed while Hearthstone has its own modal up, matching HDT's
    /// IsGameCriticalUiOpen.
    @Published var isGameCriticalUiOpen = false

    private var deckId: Int64?
    private var possiblySubscribed = false
    private var updatingAvailability = false
    private var accountUpdateTask: Task<Void, Never>?

    init(watcher: ArenaStateWatcher = Watchers.arenaStateWatcher) {
        watcher.onClientStateChanged.subscribe { [weak self] in self?.updateClientState($0) }
        watcher.onIsUndergroundChanged.subscribe { [weak self] in self?.updateUnderground($0) }
        watcher.onDeckIdChanged.subscribe { [weak self] in self?.updateDeckId($0) }
    }

    // MARK: visibility

    /// Port of HDT's `UpdateArenaPreLobbyVisibility`, whose scene test is the
    /// part that matters: `draftState` is only ever assigned while the arena
    /// state watcher is running, so it keeps its last value after the player
    /// leaves the draft screen. Without the scene check a stale `.preDraft` put
    /// this panel on top of Battlegrounds and everything else.
    ///
    /// HDT also tests IsRunning / IsInMenu / !IsInQueue; those are implied by
    /// being on the draft scene, so they are not repeated here.
    var isShown: Bool {
        Settings.enableArenasmithOverlay && Settings.showArenasmithPreLobby
            && SceneHandler.scene == .draft
            && !isGameCriticalUiOpen
            && (draftState == .preDraft || draftState == .midDraft)
    }

    var arenasmithAvailable: ArenasmithAvailability {
        guard let availabilities else { return .loading }
        return availabilities.isAvailable(isUnderground: isUnderground) ? .available : .unavailable
    }

    // MARK: watcher events

    private func updateClientState(_ state: ArenaClientState) {
        let isOnLanding = state.clientState.isLanding
        // The draft only actually starts from these session states; anything else
        // on the landing screen (rewards, a finished run) is not one click away.
        let isOneClickAway = isOnLanding
            && (state.sessionState == .no_run || state.sessionState == .drafting || state.sessionState == .redrafting)

        let newState: ArenaDraftState
        if isOneClickAway {
            newState = state.sessionState == .no_run ? .preDraft : .midDraft
        } else {
            newState = .other
        }

        guard newState != draftState else { return }
        draftState = newState
        Task { await update() }
    }

    private func updateUnderground(_ underground: Bool) {
        isUnderground = underground
        Task { await ensureAvailabilities() }
    }

    private func updateDeckId(_ id: Int64) {
        deckId = id > 0 ? id : nil
        Task { await update() }
    }

    // MARK: derived text

    /// While starter trials remain the panel shows the plain total; afterwards it
    /// switches to "used / max" for the recurring allowance.
    var remainingTrials: String {
        if let starter = starterTrialsRemaining, starter > 0 {
            return "\(starter + (recurringTrialsRemaining ?? 0))"
        }
        if let max = maxTrialUses {
            return "\(recurringTrialsRemaining ?? 0)/\(max)"
        }
        if let recurring = recurringTrialsRemaining {
            return "\(recurring)"
        }
        return "?"
    }

    /// Only meaningful once the starter trials are gone - before that there is
    /// nothing waiting on a reset.
    var showResetTime: Bool {
        starterTrialsRemaining == 0 && trialTimeRemaining != nil
    }

    var refreshSubscriptionState: ArenaRefreshSubscriptionState {
        if isAuthenticated != false && !possiblySubscribed
            && (starterTrialsRemaining ?? 0) > 0 && (recurringTrialsRemaining ?? 0) > 0 {
            return .hidden
        }
        return isAuthenticated == true ? .refresh : .signIn
    }

    // MARK: sale banner

    private var saleData: SaleData? { RemoteConfig.data?.sales?.traditional }

    var saleTagVisibility: Bool { saleData?.enabled ?? false }

    var saleTooltipVisibility: Bool {
        guard let saleData, saleData.enabled else { return false }
        return Settings.ignoreTraditionalSaleId < saleData.id
    }

    var saleDescription: String {
        guard let saleData, saleData.enabled else { return "" }
        // Shared verbatim with the Constructed pre-lobby, as in HDT.
        return String(format: String.localizedString("TraditionalPreLobby_SaleTooltip_Description", comment: ""),
                      saleData.discount)
    }

    // MARK: state

    private func ensureAvailabilities() async {
        let result = await ArenasmithStatusManager.instance.ensureAvailabilities()
        await MainActor.run { availabilities = result }
    }

    func invalidateUserState() {
        userState = .invalidated
    }

    func toggleCollapsed() {
        isCollapsed.toggle()
        Settings.arenasmithPreLobbyTrialsCollapsed = isCollapsed
    }

    func onFocus() {
        possiblySubscribed = true
        objectWillChange.send()
    }

    /// `isShown` reads `Settings.showArenasmithPreLobby` directly, so the
    /// preferences pane has to nudge SwiftUI to re-read it.
    func settingsChanged() {
        objectWillChange.send()
    }

    func reset() {
        // Not in HDT's Reset(), which can leave DraftState alone because its
        // visibility is recomputed from the scene on every transition. Clearing
        // it here keeps the published state honest once the draft is over, and
        // is what re-renders the panel away.
        draftState = .other
        ArenasmithStatusManager.instance.clear()
        availabilities = nil
        userState = .loading
        trialTimeRemaining = nil
        username = nil
        isAuthenticated = nil
        possiblySubscribed = false
        ArenaTrial.instance.clear()
    }

    func update() async {
        if (draftState == .preDraft || draftState == .midDraft) && !updatingAvailability {
            updatingAvailability = true
            await ensureAvailabilities()
            updatingAvailability = false
        }

        var ownsPremium = false
        if HSReplayAPI.isFullyAuthenticated && HSReplayAPI.accountData != nil {
            if userState == .loading {
                // Refreshing account data itself triggers another update(), so the
                // in-flight task is shared rather than restarted.
                if let existing = accountUpdateTask {
                    await existing.value
                } else {
                    let task = Task { _ = await HSReplayAPI.getAccountAsync() }
                    accountUpdateTask = task
                    await task.value
                    accountUpdateTask = nil
                }
            }
            await MainActor.run { isAuthenticated = true }
            ownsPremium = HSReplayAPI.accountData?.is_premium ?? false
        } else {
            await MainActor.run { isAuthenticated = false }
        }

        let battleTag = MirrorHelper.getBattleTag()
        let accountId = MirrorHelper.getAccountId()

        await MainActor.run {
            username = battleTag ?? HSReplayAPI.accountData?.username
        }

        guard !ownsPremium else {
            await MainActor.run {
                trialTimeRemaining = nil
                userState = .subscriber
            }
            return
        }

        guard let accountId else {
            // No Blizzard account id means no way to key trials to this player.
            await MainActor.run { userState = .unknownPlayer }
            return
        }

        let hi = accountId.hi.int64Value
        let lo = accountId.lo.int64Value
        await ArenaTrial.instance.ensureLoaded(hi: hi, lo: lo)

        let trials = ArenaTrial.instance.remainingTrials
        let timeRemaining = ArenaTrial.instance.timeRemaining
        let maxRecurring = ArenaTrial.instance.maxRecurringTrials ?? 0
        let resumable = deckId.map { ArenaTrial.instance.isDeckResumable($0) } ?? false

        await MainActor.run {
            trialTimeRemaining = timeRemaining
            starterTrialsRemaining = trials?.starter
            recurringTrialsRemaining = trials?.recurring
            maxTrialUses = maxRecurring
            userState = .trialPlayer
            isTrialEnabledForDeck = resumable
        }
    }

    // MARK: commands

    func subscribeNow() {
        let url = Helper.buildHsReplayNetUrl("arenasmith/", "arena_lobby_subscribe")
        if let url = URL(string: url) {
            NSWorkspace.shared.open(url)
        }
        possiblySubscribed = true
        objectWillChange.send()
    }

    func viewArenaStats() {
        let url = Helper.buildHsReplayNetUrl("arena/cards", "arena_lobby_view_stats",
                                             nil, ["gameType=UNDERGROUND_ARENA"])
        if let url = URL(string: url) {
            NSWorkspace.shared.open(url)
        }
        possiblySubscribed = true
        objectWillChange.send()
    }

    func signIn() {
        AppDelegate.instance().openPreferences(pane: Preferences.PaneIdentifier.hsreplay)
    }

    func refreshAccount() {
        Task.detached { [weak self] in
            guard let self else { return }
            await MainActor.run {
                self.refreshAccountEnabled = false
                self.userState = .loading
            }
            // HDT pairs the refresh with a 3s floor so the button doesn't flicker
            // back to enabled before the user sees anything happen.
            async let accountUpdate: GetAccountResult = HSReplayAPI.getAccountAsync()
            async let delay: Void = { try? await Task.sleep(nanoseconds: 3_000_000_000) }()
            _ = await (accountUpdate, delay)
            await self.update()
            await MainActor.run {
                self.refreshAccountEnabled = true
                self.possiblySubscribed = true
            }
        }
    }

    func closeSaleTooltip() {
        Settings.ignoreTraditionalSaleId = saleData?.id ?? -1
        // saleTooltipVisibility is computed, so nothing else would tell SwiftUI to
        // re-read it after this write.
        objectWillChange.send()
    }
}
