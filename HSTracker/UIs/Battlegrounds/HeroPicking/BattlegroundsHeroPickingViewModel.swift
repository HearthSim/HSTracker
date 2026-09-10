//
//  HeroPicking.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/4/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation
import SwiftUI

// Port of HDT's BattlegroundsHeroPickingViewModel
// (Controls/Overlay/Battlegrounds/HeroPicking/BattlegroundsHeroPickingViewModel.cs).
@available(macOS 10.15, *)
class BattlegroundsHeroPickingViewModel: ObservableObject {
    @Published private var _isViewingTeammate = false
    @Published private(set) var heroStats: [BattlegroundsSingleHeroViewModel]?
    @Published private var _statsVisibility = false

    let message = OverlayMessageViewModel()

    init() {
        // OverlayMessageViewModel is still the AppKit-era ViewModel - the quest
        // and trinket pickers, both still AppKit, share it - so it can't carry
        // @Published of its own without being gated to the SwiftUI baseline.
        // Republishing its changes from here is what keeps the message this
        // panel draws in sync with it.
        message.propertyChanged = { [weak self] _ in
            self?.onMain {
                self?.objectWillChange.send()
            }
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

    // HDT's Visibility is just "we have stats and aren't looking at a
    // teammate's board"; the extra gate is HSTracker's own, which switches the
    // overlay off wholesale from Battlegrounds preferences rather than through
    // HDT's in-overlay show/hide toggle.
    var visibility: Bool {
        if !Settings.showBattlegroundsHeroPicking || isViewingTeammate {
            return false
        }
        return heroStats != nil
    }

    // Gates the stats themselves, which fade in once they have loaded.
    var statsVisibility: Bool {
        get {
            return _statsVisibility
        }
        set {
            onMain { self._statsVisibility = newValue }
        }
    }

    func reset() {
        onMain {
            self.heroStats = nil
            self._isViewingTeammate = false
            self._statsVisibility = false
            self.message.clear()
        }
    }

    func setHeroStats(stats: [BattlegroundsHeroPickStats.BattlegroundsSingleHeroPickStats], parameters: [String: String]?, minMmr: Int?, anomalyadjusted: Bool) {
        let filterValue = parameters?["mmrPercentile"]

        onMain {
            withAnimation(.easeInOut(duration: Self.fadeDuration)) {
                self.heroStats = stats.compactMap { x in BattlegroundsSingleHeroViewModel(stats: x, onPlacementHover: self.setPlacementVisible) }

                self.message.mmr(filterValue: filterValue, minMMR: minMmr, anomalyAdjusted: anomalyadjusted)

                self._statsVisibility = Settings.showBattlegroundsHeroPicking
            }
        }
    }

    func invalidateSingleHeroStats(_ dbfId: Int) {
        onMain {
            self.heroStats = self.heroStats?.compactMap { x in x.heroDbfId == dbfId ? BattlegroundsSingleHeroViewModel(stats: nil, onPlacementHover: self.setPlacementVisible) : x }
        }
    }

    // Hovering any one hero's average placement reveals the placement
    // distribution on every hero at once.
    func setPlacementVisible(_ isVisible: Bool) {
        onMain {
            guard let heroStats = self.heroStats else {
                return
            }
            for hero in heroStats {
                hero.bgsHeroHeaderVM.placementDistributionVisibility = isVisible
            }
        }
    }

    // anim:FadeAnimation.Duration="0:0:0.2" on the stats grid.
    static let fadeDuration = 0.2

    // The log reader, the watchers and BobsBuddy all call in from their own
    // threads, and @Published has to be written on the main one.
    private func onMain(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }
}
