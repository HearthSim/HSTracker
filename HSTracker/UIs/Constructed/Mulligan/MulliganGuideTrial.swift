//
//  MulliganGuideTrial.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/10/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

// Persisted across app relaunches (matches HDT's own JsonSerializer<TrialData>
// file, ported here as a JSON string in UserDefaults instead) so a trial
// activated earlier in the SAME match is reused rather than burning a second
// one, and so "the player's last trial was just used" survives until they're
// back in the lobby to see the one-time alert for it.
private struct MulliganGuideTrialData: Codable {
    var token: String?
    var gameHandle: Int?
    var lastTrialAlertPending: Bool
}

@available(macOS 10.15.0, *)
class MulliganGuideTrial {
    private static var _status: PlayerTrialStatus?
    static private(set) var token: String?

    static var remainingTrials: Int? {
        return _status?.trials_remaining
    }

    static var timeRemaining: String? {
        guard let hours = _status?.hours_til_next_reset else { return nil }
        return String(format: String.localizedString("BattlegroundsPreLobby_Trial_ResetTimeRemaining_DaysHours", comment: ""), hours / 24, hours % 24)
    }

    private static var persistedData: MulliganGuideTrialData {
        get {
            guard let json = Settings.mulliganGuideTrialData,
                  let data = json.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode(MulliganGuideTrialData.self, from: data) else {
                return MulliganGuideTrialData(token: nil, gameHandle: nil, lastTrialAlertPending: false)
            }
            return decoded
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue), let json = String(data: data, encoding: .utf8) else {
                return
            }
            Settings.mulliganGuideTrialData = json
        }
    }

    // Matches HDT's MulliganGuideTrial.ActivateOrContinue(): reuses the
    // trial already activated for this same match (identified by
    // gameHandle) instead of burning a second one, and otherwise activates
    // a new one - recording whether this was the player's *last* remaining
    // trial so the pre-lobby can show a one-time "trials exhausted" alert
    // once they're back from the match.
    static func activateOrContinue(hi: Int64, lo: Int64, gameHandle: Int?) async -> String? {
        guard let gameHandle else {
            return nil
        }

        let current = persistedData
        if current.gameHandle == gameHandle, let existingToken = current.token {
            token = existingToken
            return existingToken
        }

        guard let status = _status, (status.trials_remaining ?? 0) > 0 else {
            return nil
        }
        // Not decremented locally - trials_remaining still reflects the
        // pre-activation count here.
        let isLastTrial = (status.trials_remaining ?? 0) == 1

        guard let newToken = await HSReplayAPI.activatePlayerTrial(name: "mulligan-guide-overlay", hi: hi, lo: lo)?.token else {
            return nil
        }
        token = newToken
        persistedData = MulliganGuideTrialData(token: newToken, gameHandle: gameHandle, lastTrialAlertPending: isLastTrial)
        return newToken
    }

    // Read-and-clear: returns true (once) if the most recent trial
    // activation consumed the player's last one, so the pre-lobby can show
    // the "trials exhausted" alert exactly once.
    static func consumePendingLastTrialAlert() -> Bool {
        var data = persistedData
        if !data.lastTrialAlertPending {
            return false
        }
        data.lastTrialAlertPending = false
        persistedData = data
        return true
    }

    static func update(hi: Int64, lo: Int64) async {
        if _status?.hours_til_next_reset ?? 0 < 2 {
            _status = nil
        }
        _status = await HSReplayAPI.getPlayerTrialStatus(name: "mulligan-guide-overlay", hi: hi, lo: lo)
    }

    // In-memory only, matching HDT's own Clear() - the persisted per-game
    // activation record deliberately survives so a later match's
    // ActivateOrContinue can still detect a stale/mismatched gameHandle.
    static func clear() {
        _status = nil
        token = nil
    }
}
