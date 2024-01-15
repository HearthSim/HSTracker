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
    private static var _status: PlayerTrialStatus?
    static private(set) var token: String?
    static var remainingTrials: Int? { return _status?.trials_remaining }
    static var timeRemaining: String? {
        guard let hours = _status?.hours_til_next_reset else {
            return nil
        }
        return String(format: String.localizedString("BattlegroundsPreLobby_Trial_ResetTimeRemaining_DaysHours", comment: ""), hours / 24, hours % 24)
    }
    static func activate(hi: Int64, lo: Int64) async -> String? {
        if token != nil {
            return nil
        }
        if _status == nil || _status?.trials_remaining == 0 {
            return nil
        }
        token = await HSReplayAPI.activatePlayerTrial(name: "tier7-overlay", hi: hi, lo: lo)?.token
        return token
    }
    
    static func update(hi: Int64, lo: Int64) async {
        if _status?.hours_til_next_reset ?? 0 < 2 {
            _status = nil
        }
        _status = await HSReplayAPI.getPlayerTrialStatus(name: "tier7-overlay", hi: hi, lo: lo)
    }
    
    static func clear() {
        _status = nil
        token = nil
    }
}
