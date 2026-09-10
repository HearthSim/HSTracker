//
//  BattlegroundsTrinketPickingViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/23/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation
import SwiftUI

// Port of HDT's BattlegroundsTrinketPickingViewModel
// (Controls/Overlay/Battlegrounds/TrinketPicking/BattlegroundsTrinketPickingViewModel.cs).
@available(macOS 10.15, *)
class BattlegroundsTrinketPickingViewModel: ObservableObject {
    @Published private var _choicesVisible = false
    @Published private(set) var trinketStats: [StatsHeaderViewModel]?
    @Published private var _statsVisibility = false

    let message = OverlayMessageViewModel()

    init() {
        // The message view model is still the AppKit-era ViewModel, shared with
        // the quest picker; republishing its changes here is what keeps the
        // message this panel draws in sync with it.
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

    var visibility: Bool {
        return _choicesVisible && trinketStats != nil && (trinketStats?.count ?? 0) > 0
    }

    // Whether the stats themselves are shown, which the overlay's own toggle
    // flips and Config.AutoShowBattlegroundsTrinketPicking remembers.
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
            ? String.localizedString("BattlegroundsTrinketPicking_VisibilityToggle_Hide", comment: "")
            : String.localizedString("BattlegroundsTrinketPicking_VisibilityToggle_Show", comment: "")
    }

    // OverlayVisibilityToggle_MouseUp.
    func toggleStatsVisibility() {
        let newVisibility = !_statsVisibility
        withAnimation(.easeInOut(duration: Self.fadeDuration)) {
            _statsVisibility = newVisibility
        }
        Settings.autoShowBattlegroundsTrinketPicking = newVisibility
    }

    func showErrorMessage() {
        message.error()
    }

    func showDisabledMessage() {
        message.disabled()
    }

    func reset() {
        onMain {
            self.trinketStats = nil
            self.message.clear()
        }
    }

    func setTrinketStats(_ stats: [BattlegroundsTrinketPickStats.BattlegroundsSingleTrinketPickStats]) {
        onMain {
            withAnimation(.easeInOut(duration: Self.fadeDuration)) {
                self.trinketStats = stats.compactMap { x in StatsHeaderViewModel(tier: x.tier, avgPlacement: x.avg_placement, pickRate: x.pick_rate, dbfId: x.trinket_dbf_id) }
                self._statsVisibility = Settings.autoShowBattlegroundsTrinketPicking
            }
        }
    }

    // anim:FadeAnimation.Duration="0:0:0.2" on the stats grid.
    static let fadeDuration = 0.2

    // The log reader calls in from its own thread, and @Published has to be
    // written on the main one.
    private func onMain(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }
}
