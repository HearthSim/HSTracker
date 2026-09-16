//
//  CountersOverlayViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/9/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Replaces the CountersOverlay window controller, keeping the bookkeeping it
// carried (which counters are currently visible, their Battlegrounds order,
// and the example counters shown while the overlay is unlocked) now that the
// counters are a child of the RootOverlay canvas instead of a window of their
// own. Mirrors HDT's CountersOverlay.xaml.cs, whose VisibleCounters collection
// this is.
//
// Every mutating entry point hops to the main thread rather than being
// @MainActor: the counter-changed listener fires from the log reader queue,
// and the call sites (AppDelegate's lock/unlock menu item, Game) are plain
// synchronous code.
@available(macOS 10.15, *)
class CountersOverlayViewModel: ObservableObject {
    // HDT's IsPlayer on the two CountersOverlay instances.
    let isPlayer: Bool

    // HDT's Visibility on the control, driven by Game.updateCounters the way
    // OverlayWindow.UpdateCounters drives it there.
    @Published var isShown = false

    @Published private(set) var chips: [CounterChipViewModel] = []

    // Core.Game.IsBattlegroundsMatch, which HDT's CountersOverlay reads in two
    // places: SortVisibleCounters and WrapWidth. Republished with the chips so
    // the view can break the rows without reaching for the game itself on every
    // layout pass - see CountersOverlayView.wrapWidth.
    @Published private(set) var isBattlegroundsMatch = false

    private var counterManager: CounterManager?

    // While example counters are up they stand in for the real list, so a
    // counter changing in the background must not overwrite them.
    private var showingExamples = false

    init(isPlayer: Bool) {
        self.isPlayer = isPlayer
    }

    func setCounters(_ counterManager: CounterManager) {
        self.counterManager = counterManager
        counterManager.addCountersChangedListener { [weak self] in
            self?.updateVisibleCounters()
        }
    }

    func updateVisibleCounters() {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.updateVisibleCounters()
            }
            return
        }
        guard let counterManager, !showingExamples else { return }

        let visible = counterManager.getVisibleCounters(controlledByPlayer: isPlayer)

        // Amended in place rather than rebuilt from `visible`, so a counter that
        // was already on screen keeps its position in the row (and its chip's
        // already-loaded art) when another one appears or disappears - HDT
        // maintains its ObservableCollection the same way.
        var updated = chips.filter { visible.contains($0.counter) }
        let kept = updated.map { $0.counter }
        for counter in visible where !kept.contains(counter) {
            updated.append(CounterChipViewModel(counter: counter))
        }

        setChips(updated)
    }

    // HDT's SortVisibleCounters: ordered in Battlegrounds only, left alone
    // everywhere else.
    private func setChips(_ chips: [CounterChipViewModel]) {
        let isBattlegroundsMatch = AppDelegate.instance().coreManager.game.isBattlegroundsMatch()
        self.isBattlegroundsMatch = isBattlegroundsMatch
        self.chips = isBattlegroundsMatch
            ? chips.sorted { $0.counter.sortValue < $1.counter.sortValue }
            : chips
    }

    func forceShowExampleCounters() {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.forceShowExampleCounters()
            }
            return
        }
        guard let counterManager else { return }
        showingExamples = true
        setChips(counterManager.getExampleCounters(controlledByPlayer: isPlayer)
            .map { CounterChipViewModel(counter: $0) })
    }

    func forceHideExampleCounters() {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.forceHideExampleCounters()
            }
            return
        }
        showingExamples = false
        setChips([])
        updateVisibleCounters()
    }
}
