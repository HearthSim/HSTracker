//
//  ActiveEffectsOverlayViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/14/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// Replaces the ActiveEffectsOverlay window controller, keeping the bookkeeping
// it carried (which effects are currently visible, and the example effects
// shown while the overlay is unlocked) now that the effects are a child of the
// RootOverlay canvas instead of a window of their own. Mirrors HDT's
// ActiveEffectsOverlay.xaml.cs, whose VisibleEffects collection this is.
@available(macOS 10.15, *)
class ActiveEffectsOverlayViewModel: ObservableObject {
    // HDT's IsPlayer on the two ActiveEffectsOverlay instances.
    let isPlayer: Bool

    // HDT's Visibility on the control, driven by Game.updateActiveEffects the
    // way OverlayWindow.UpdateActiveEffects drives it there.
    @Published var isShown = false

    @Published private(set) var effects: [ActiveEffectViewModel] = []

    private var activeEffects: ActiveEffects?

    // While example effects are up they stand in for the real list, so an
    // effect changing in the background must not overwrite them.
    private var showingExamples = false

    init(isPlayer: Bool) {
        self.isPlayer = isPlayer
    }

    func setActiveEffects(_ activeEffects: ActiveEffects) {
        self.activeEffects = activeEffects
    }

    func updateVisibleEffects() {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.updateVisibleEffects()
            }
            return
        }
        guard !showingExamples, let activeEffects else { return }

        var updated = [ActiveEffectViewModel]()
        let effectsByCardId = activeEffects.getVisibleEffects(controlledByPlayer: isPlayer).group({ x in x.cardId })

        for effects in effectsByCardId.values {
            let effect = effects[0]
            let effectCount = effects.count
            let count = effect.showNumberInPlay && effectCount > 1 ? effectCount : nil
            updated.append(ActiveEffectViewModel(effect: effect, count: count))
        }

        effects = updated
    }

    // HDT's ForceShowExampleEffects, shown while the overlay is unlocked so
    // there is something to drag. It fills both rows with Preparation; the
    // AppKit overlay this replaces used four Preparations and four Waves of
    // Apathy, which is kept.
    func forceShowExampleEffects() {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.forceShowExampleEffects()
            }
            return
        }
        showingExamples = true

        var updated = [ActiveEffectViewModel]()
        let preparation = PreparationEnchantment(entityId: 0, isControlledByPlayer: isPlayer)
        for _ in 0 ..< 4 {
            updated.append(ActiveEffectViewModel(effect: preparation))
        }
        let wave = WaveOfApathyEnchantment(entityId: 0, isControlledByPlayer: isPlayer)
        for _ in 0 ..< 4 {
            updated.append(ActiveEffectViewModel(effect: wave, count: 3))
        }
        effects = updated
    }

    func forceHideExampleEffects() {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.forceHideExampleEffects()
            }
            return
        }
        showingExamples = false
        updateVisibleEffects()
    }
}
