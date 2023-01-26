//
//  Tier7Trial.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/9/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

@available(macOS 10.15.0, *)
class Tier7Trial {
    private static var _status: Tier7TrialStatus?
    static private(set) var isActive: Bool = false
    static var remainingTrials: Int? { return _status?.trials_remaining }
    static var timeRemaining: String? {
        guard let hours = _status?.hours_til_next_reset else {
            return nil
        }
        return String(format: NSLocalizedString("BattlegroundsPreLobby_Trial_ResetTimeRemaining_DaysHours", comment: ""), hours / 24, hours % 24)
    }
    static func activate() async -> Bool {
        if isActive {
            return true
        }
        if _status == nil || _status?.trials_remaining == 0 {
            return false
        }
        let response = await HSReplayAPI.activateTier7Trial()
        isActive = response != nil
        return isActive
    }
    
    static func update() async {
        if _status?.hours_til_next_reset ?? 0 < 2 {
            _status = nil
        }
        _status = await HSReplayAPI.getTier7TrialStatus()
    }
    
    static func clear() {
        _status = nil
        isActive = false
    }
}
