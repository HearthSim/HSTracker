//
//  BattlegroundsCompsGuidesViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

enum CompGuideListState {
    case loading, baseFeature, tier7Feature, empty, error
}

// Mirrors HDT's BattlegroundsCompsGuidesViewModel state machine. Ported as a
// plain ObservableObject instead of the legacy ViewModel/getProp pattern -
// see RootOverlayViewModel for the SwiftUI overlay convention this attaches
// to.
final class BattlegroundsCompsGuidesViewModel: ObservableObject {
    @Published var comps: [BattlegroundsCompGuideViewModel]?
    @Published var compsByTier: [Int: [BattlegroundsCompGuideViewModel]]?
    @Published var currentState: CompGuideListState = .loading
    @Published var selectedComp: BattlegroundsCompGuideViewModel?
    @Published var hasError = false
    @Published var isRetrying = false
    @Published var hasRetriedAndFailed = false

    // HDT's IsPreLobby: the guides are showing in the Battlegrounds lobby,
    // before a match has started. Two things differ there - there is no minion
    // pool yet, so the premium request asks for the unfiltered list, and no
    // Tier7 trial is activated (spending one before the player has even queued
    // is not worth it).
    @Published private(set) var isPreLobby = false

    var isCompSelected: Bool { selectedComp != nil }

    // Serializes concurrent fetches (match start + a user-triggered retry
    // landing at the same time) - mirrors HDT's SemaphoreSlim(1,1) guard.
    private let updateLock = NSLock()

    // HDT's OnMinionPoolChanged, which re-raises each guide's CoreCards and
    // AddonCards. These view models are structs that work out card
    // availability when they are built, so they are rebuilt instead.
    @MainActor
    func onMinionPoolChanged() {
        func rebuild(_ comp: BattlegroundsCompGuideViewModel) -> BattlegroundsCompGuideViewModel {
            BattlegroundsCompGuideViewModel(comp.compGuide, isPreLobby: comp.isPreLobby)
        }
        compsByTier = compsByTier?.mapValues { $0.map(rebuild) }
        comps = comps?.map(rebuild)
        selectedComp = selectedComp.map(rebuild)
    }

    func onMatchStart() async {
        await MainActor.run {
            if isPreLobby {
                isPreLobby = false
                // the guides are rebuilt below, so a comp selected in the lobby
                // would point at a stale view model
                selectedComp = nil
            }
        }
        if AppDelegate.instance().coreManager.game.spectator {
            await Task.sleep(milliseconds: 1500)
        }
        updateLock.lock()
        await trySetCompGuides()
        updateLock.unlock()
    }

    // HDT's OnPreLobby, called when the guides panel comes up in the
    // Battlegrounds lobby. Without this the panel had nothing to load it, so it
    // sat on `.loading` until a match started.
    func onPreLobby() async {
        await MainActor.run {
            isPreLobby = true
            selectedComp = nil
        }

        updateLock.lock()
        await trySetCompGuides()
        updateLock.unlock()
    }

    // Unlike hero/quest/trinket picking state, the free comp list (`comps`)
    // isn't reset here - HDT's OnMatchEnd only clears the premium, per-lobby
    // filtered result (`compsByTier`), since the free list has no lobby
    // dependency and doesn't need refetching every match.
    func onMatchEnd() {
        DispatchQueue.main.async {
            self.isPreLobby = false
            self.compsByTier = nil
            self.selectedComp = nil
            self.hasError = false
            self.hasRetriedAndFailed = false
            self.updateState()
        }
    }

    func reset() {
        DispatchQueue.main.async {
            self.isPreLobby = false
            self.comps = nil
            self.compsByTier = nil
            self.selectedComp = nil
            self.hasError = false
            self.hasRetriedAndFailed = false
            self.updateState()
        }
    }

    func retry() async {
        let alreadyRetrying: Bool = await MainActor.run {
            if isRetrying { return true }
            isRetrying = true
            hasRetriedAndFailed = false
            return false
        }
        guard !alreadyRetrying else { return }

        updateLock.lock()
        await trySetCompGuides()
        updateLock.unlock()

        await MainActor.run {
            if hasError {
                hasRetriedAndFailed = true
            }
            isRetrying = false
        }
    }

    private func trySetCompGuides() async {
        if await MainActor.run(body: { isPreLobby }) {
            // no trial is activated here, spending one before the player has
            // even queued is not worth it
            if HSReplayAPI.accountData?.is_tier7 ?? false {
                // there is no minion pool before a match, so ask for the
                // unfiltered list
                await setPremiumCompGuides(token: nil, minionTypes: [])
            } else {
                await setFreeCompGuides()
            }
            return
        }

        if !Tier7Trial.isAvailable {
            await setFreeCompGuides()
            return
        }

        let races: [Race]?
        do {
            races = try await BattlegroundsUtils.waitForAvailableRaces()
        } catch {
            return
        }
        guard let races else {
            logger.error("Unable to get available races")
            await setError()
            return
        }

        if let access = await Tier7Trial.getAccess() {
            await setPremiumCompGuides(token: access.trialToken, minionTypes: races.compactMap { Race.allCases.firstIndex(of: $0) })
        } else {
            await setFreeCompGuides()
        }
    }

    private func setPremiumCompGuides(token: String?, minionTypes: [Int]) async {
        let gameLanguage = "\(Settings.hearthstoneLanguage ?? .enUS)"

        let data = token != nil
            ? await HSReplayAPI.getTier7CompGuides(token: token, gameLanguage: gameLanguage, minionTypes: minionTypes)
            : await HSReplayAPI.getTier7CompGuides(gameLanguage: gameLanguage, minionTypes: minionTypes)

        guard let data else {
            await setError()
            return
        }

        await MainActor.run {
            // updateState prefers compsByTier, so the free list has to go
            // before it is set
            self.comps = nil
            self.compsByTier = data.by_tier.mapValues { guides in
                guides.sorted(by: { $0.tier_rank < $1.tier_rank })
                    .map { BattlegroundsCompGuideViewModel($0, isPreLobby: self.isPreLobby) }
            }
            self.hasError = false
            self.updateState()
        }
    }

    private func setFreeCompGuides() async {
        let gameLanguage = "\(Settings.hearthstoneLanguage ?? .enUS)"

        guard let data = await HSReplayAPI.getCompGuides(gameLanguage: gameLanguage) else {
            await setError()
            return
        }

        await MainActor.run {
            self.compsByTier = nil
            self.comps = data.sorted(by: { $0.name < $1.name })
                .map { BattlegroundsCompGuideViewModel($0, isPreLobby: self.isPreLobby) }
            self.hasError = false
            self.updateState()
        }
    }

    @MainActor
    private func setError() {
        hasError = true
        updateState()
    }

    @MainActor
    private func updateState() {
        if hasError {
            currentState = .error
        } else if let compsByTier {
            let hasComps = compsByTier.values.contains { !$0.isEmpty }
            currentState = hasComps ? .tier7Feature : .empty
        } else if let comps {
            currentState = comps.isEmpty ? .empty : .baseFeature
        } else {
            currentState = .loading
        }
    }
}
