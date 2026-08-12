//
//  MulliganGuideTrialsExhaustedViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/12/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation
import AppKit

// One-time heads-up shown when the player's last free trial of the
// interactive Mulligan Guide was just used up in a match - matches HDT's
// MulliganGuideTrialsExhaustedViewModel. Driven by
// Game.updateMulliganGuideTrialsExhausted(), which decides whether to show
// this based on MulliganGuideTrial.consumePendingLastTrialAlert().
@available(macOS 10.15, *)
class MulliganGuideTrialsExhaustedViewModel: ObservableObject {
    @Published var isShown = false
    @Published var trialTimeRemaining: String?

    var resetTimeVisibility: Bool {
        trialTimeRemaining != nil
    }

    @MainActor
    func close() {
        isShown = false
        AppDelegate.instance().coreManager.game.updateMulliganGuidePreLobby()
    }

    @MainActor
    func subscribeNow() {
        let url = Helper.buildHsReplayNetUrl("premium/", "constructed_trials_exhausted")
        if let url = URL(string: url) {
            NSWorkspace.shared.open(url)
        }
        close()
    }
}
