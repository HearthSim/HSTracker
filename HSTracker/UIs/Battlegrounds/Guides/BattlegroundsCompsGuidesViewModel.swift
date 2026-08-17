//
//  BattlegroundsCompsGuidesViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

@available(macOS 10.15, *)
enum CompGuideListState {
    case loading, baseFeature, tier7Feature, empty, error
}

// Mirrors HDT's BattlegroundsCompsGuidesViewModel state machine. Ported as a
// plain ObservableObject instead of the legacy ViewModel/getProp pattern -
// see RootOverlayViewModel for the SwiftUI overlay convention this attaches
// to.
@available(macOS 10.15, *)
final class BattlegroundsCompsGuidesViewModel: ObservableObject {
    @Published var comps: [BattlegroundsCompGuideViewModel]?
    @Published var compsByTier: [Int: [BattlegroundsCompGuideViewModel]]?
    @Published var currentState: CompGuideListState = .loading
    @Published var selectedComp: BattlegroundsCompGuideViewModel?
    @Published var hasError = false
    @Published var isRetrying = false
    @Published var hasRetriedAndFailed = false

    var isCompSelected: Bool { selectedComp != nil }

    // Serializes concurrent fetches (match start + a user-triggered retry
    // landing at the same time) - mirrors HDT's SemaphoreSlim(1,1) guard.
    private let updateLock = NSLock()

    @available(macOS 10.15.0, *)
    func onMatchStart() async {
        if AppDelegate.instance().coreManager.game.spectator {
            await Task.sleep(milliseconds: 1500)
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
            self.compsByTier = nil
            self.hasError = false
            self.hasRetriedAndFailed = false
            self.updateState()
        }
    }

    func reset() {
        DispatchQueue.main.async {
            self.comps = nil
            self.compsByTier = nil
            self.selectedComp = nil
            self.hasError = false
            self.hasRetriedAndFailed = false
            self.updateState()
        }
    }

    @available(macOS 10.15.0, *)
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

    @available(macOS 10.15.0, *)
    private func trySetCompGuides() async {
        let game = AppDelegate.instance().coreManager.game
        let userOwnsTier7 = HSReplayAPI.accountData?.is_tier7 ?? false
        let token = Tier7Trial.token
        let gameLanguage = "\(Settings.hearthstoneLanguage ?? .enUS)"

        if userOwnsTier7 || token != nil {
            // game.availableRaces reads live from a game-memory mirror and
            // returns nil until that read settles - right at match start
            // it's reliably nil for roughly a second, so checking it once
            // here would error out on every first load (and only succeed on
            // Retry, once the mirror had time to catch up). Poll briefly
            // instead of failing on the first nil.
            var races: [Race]?
            for _ in 0..<10 {
                if let r = game.availableRaces {
                    races = r
                    break
                }
                await Task.sleep(milliseconds: 300)
            }
            guard let races else {
                await setError()
                return
            }
            let minionTypes = races.compactMap { Race.allCases.firstIndex(of: $0) }

            let data = token != nil
                ? await HSReplayAPI.getTier7CompGuides(token: token, gameLanguage: gameLanguage, minionTypes: minionTypes)
                : await HSReplayAPI.getTier7CompGuides(gameLanguage: gameLanguage, minionTypes: minionTypes)

            guard let data else {
                await setError()
                return
            }

            await MainActor.run {
                self.compsByTier = data.by_tier.mapValues { guides in
                    guides.sorted(by: { $0.tier_rank < $1.tier_rank }).map { BattlegroundsCompGuideViewModel($0) }
                }
                self.hasError = false
                self.updateState()
            }
        } else {
            guard let data = await HSReplayAPI.getCompGuides(gameLanguage: gameLanguage) else {
                await setError()
                return
            }
            await MainActor.run {
                self.comps = data.sorted(by: { $0.name < $1.name }).map { BattlegroundsCompGuideViewModel($0) }
                self.hasError = false
                self.updateState()
            }
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
