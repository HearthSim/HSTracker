//
//  BattlegroundsHeroPowerPickingViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/10/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation
import SwiftUI

// Port of HDT's BattlegroundsSingleHeroPowerViewModel: one hero power offered by
// Sir Finley's start of game choice, rated with the stats of the hero it belongs
// to, whose portrait floats below it.
class BattlegroundsSingleHeroPowerViewModel: ObservableObject {
    let bgsHeroHeaderVM: BattlegroundsHeroHeaderViewModel

    let armor: Int?

    var armorVisibility: Bool {
        return (armor ?? 0) > 0
    }

    // CardAssetViewModel(..., CardAssetType.Hero), the same hero render the
    // Inspiration panel draws.
    @Published private(set) var heroImage: NSImage?

    init(heroPowerDbfId: Int, stats: BattlegroundsHeroPickStats.BattlegroundsSingleHeroPickStats?, onPlacementHover: @escaping (Bool) -> Void) {
        armor = stats?.armor
        bgsHeroHeaderVM = BattlegroundsHeroHeaderViewModel(tier: stats?.tier_v2, avgPlacement: stats?.avg_placement, pickRate: stats?.pick_rate, placementDistribution: stats?.placement_distribution ?? [Double](repeating: 0.0, count: 8), onPlacementHover: onPlacementHover)

        let heroDbfId = Cards.by(dbfId: heroPowerDbfId, collectible: false)?.baconHeroPowerBaseHeroId ?? 0
        if heroDbfId > 0, let heroId = Cards.by(dbfId: heroDbfId, collectible: false)?.id {
            loadHeroImage(heroId)
        }
    }

    private func loadHeroImage(_ heroId: String) {
        if let cached = ImageUtils.cachedHero(cardId: heroId) {
            heroImage = cached
            return
        }
        ImageUtils.hero(for: heroId) { [weak self] image in
            DispatchQueue.main.async { self?.heroImage = image }
        }
    }
}

// Port of HDT's BattlegroundsHeroPowerPickingViewModel
// (Controls/Overlay/Battlegrounds/HeroPowerPicking/BattlegroundsHeroPowerPickingViewModel.cs):
// the hero pick stats shown over the hero powers Sir Finley offers at the start
// of a game.
class BattlegroundsHeroPowerPickingViewModel: ObservableObject {
    @Published private var _choicesVisible = false
    @Published private var _isViewingTeammate = false
    @Published private(set) var heroPowerStats: [BattlegroundsSingleHeroPowerViewModel]?
    @Published private var _statsVisibility = false

    let message = OverlayMessageViewModel()

    init() {
        // The message view model is still the AppKit-era ViewModel; republishing
        // its changes here keeps the message this panel draws in sync with it.
        message.propertyChanged = { [weak self] _ in
            self?.onMain {
                self?.objectWillChange.send()
            }
        }
    }

    // Game.setChoicesVisible, off the log reader's thread.
    var choicesVisible: Bool {
        get {
            return _choicesVisible
        }
        set {
            onMain { self._choicesVisible = newValue }
        }
    }

    // BattlegroundsTeammateBoardStateWatcher pushes this from its own thread.
    var isViewingTeammate: Bool {
        get {
            return _isViewingTeammate
        }
        set {
            onMain { self._isViewingTeammate = newValue }
        }
    }

    var visibility: Bool {
        return _choicesVisible && !_isViewingTeammate && heroPowerStats != nil
    }

    var statsVisibility: Bool {
        get {
            return _statsVisibility
        }
        set {
            onMain { self._statsVisibility = newValue }
        }
    }

    var visibilityToggleIcon: String {
        return _statsVisibility ? "eye_slash" : "eye"
    }

    var visibilityToggleText: String {
        return _statsVisibility
            ? String.localizedString("BattlegroundsHeroPicking_VisibilityToggle_Hide", comment: "")
            : String.localizedString("BattlegroundsHeroPicking_VisibilityToggle_Show", comment: "")
    }

    // OverlayVisibilityToggle_MouseUp, which shares ShowBattlegroundsHeroPicking
    // with the hero picker.
    func toggleStatsVisibility() {
        let newVisibility = !_statsVisibility
        withAnimation(.easeInOut(duration: Self.fadeDuration)) {
            _statsVisibility = newVisibility
        }
        Settings.showBattlegroundsHeroPicking = newVisibility
    }

    func showErrorMessage() {
        message.error()
    }

    func showDisabledMessage() {
        message.disabled()
    }

    func reset() {
        onMain {
            self.heroPowerStats = nil
            self._isViewingTeammate = false
            self.message.clear()
        }
    }

    func setHeroPowerStats(heroPowerDbfIds: [Int], stats: [BattlegroundsHeroPickStats.BattlegroundsSingleHeroPickStats], parameters: [String: String]?, minMmr: Int?, anomalyAdjusted: Bool) {
        let filterValue = parameters?["mmrPercentile"]

        onMain {
            withAnimation(.easeInOut(duration: Self.fadeDuration)) {
                self.heroPowerStats = heroPowerDbfIds.map { dbfId in
                    BattlegroundsSingleHeroPowerViewModel(heroPowerDbfId: dbfId, stats: stats.first { x in x.hero_dbf_id == dbfId }, onPlacementHover: self.setPlacementVisible)
                }

                self.message.mmr(filterValue: filterValue, minMMR: minMmr, anomalyAdjusted: anomalyAdjusted)

                self._statsVisibility = Settings.showBattlegroundsHeroPicking
            }
        }
    }

    // Hovering any one hero power's average placement reveals the placement
    // distribution on all of them at once.
    func setPlacementVisible(_ isVisible: Bool) {
        onMain {
            guard let heroPowerStats = self.heroPowerStats else {
                return
            }
            for heroPower in heroPowerStats {
                heroPower.bgsHeroHeaderVM.placementDistributionVisibility = isVisible
            }
        }
    }

    // anim:FadeAnimation.Duration="0:0:0.2" on the stats grid.
    static let fadeDuration = 0.2

    // The log reader and the watchers call in from their own threads, and
    // @Published has to be written on the main one.
    private func onMain(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }
}
