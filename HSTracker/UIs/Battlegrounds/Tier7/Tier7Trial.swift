//
//  Tier7Trial.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/9/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

// Persisted across app relaunches (HDT's JsonSerializer<TrialData> file, kept
// as a JSON string in UserDefaults as MulliganGuideTrial does) so a trial
// activated earlier in the same match is continued rather than spending a
// second one.
private struct Tier7TrialData: Codable {
    var token: String?
    var gameHandle: Int?
}

// HDT's Tier7Access: what a Tier7 request goes through.
final class Tier7Access {
    static let subscription = Tier7Access(trialToken: nil)

    // nil for subscribers, whose requests go through OAuth instead
    let trialToken: String?

    fileprivate init(trialToken: String?) {
        self.trialToken = trialToken
    }
}

// HDT's SemaphoreSlim(1, 1) around ActivateOrContinue. Callers race at the
// start of a match (hero picking and the session comp stats), and only one of
// them may spend the trial.
private actor Tier7TrialMutex {
    private var locked = false
    private var waiters = [CheckedContinuation<Void, Never>]()

    func lock() async {
        if !locked {
            locked = true
            return
        }
        await withCheckedContinuation { waiters.append($0) }
    }

    func unlock() {
        if waiters.isEmpty {
            locked = false
        } else {
            waiters.removeFirst().resume()
        }
    }
}

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

    private static let mutex = Tier7TrialMutex()

    private static var persistedData: Tier7TrialData {
        get {
            guard let json = Settings.tier7TrialData,
                  let data = json.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode(Tier7TrialData.self, from: data) else {
                return Tier7TrialData(token: nil, gameHandle: nil)
            }
            return decoded
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue), let json = String(data: data, encoding: .utf8) else {
                return
            }
            Settings.tier7TrialData = json
        }
    }

    private static var currentGameHandle: Int? {
        return AppDelegate.instance().coreManager.game.serverInfo?.gameHandle as? Int
    }

    static func isTrialForCurrentGameActive(_ gameHandle: Int?) -> Bool {
        return persistedData.gameHandle == gameHandle
    }

    static var isAvailable: Bool {
        if HSReplayAPI.accountData?.is_tier7 ?? false {
            return true
        }
        if (remainingTrials ?? 0) > 0 && canActivateNewTrial {
            return true
        }
        if let gameHandle = currentGameHandle, isTrialForCurrentGameActive(gameHandle) {
            return true
        }
        return false
    }

    private static var canActivateNewTrial: Bool {
        return (AppDelegate.instance().coreManager.game.gameEntity?[.step] ?? 0) <= Step.begin_mulligan.rawValue
    }

    // Call only once all request preconditions are met (so a trial is never wasted).
    static func getAccess() async -> Tier7Access? {
        if HSReplayAPI.accountData?.is_tier7 ?? false {
            return Tier7Access.subscription
        }

        guard let gameHandle = currentGameHandle else {
            return nil
        }

        guard let acc = MirrorHelper.getAccountId() else {
            return nil
        }

        guard let token = await activateOrContinue(hi: acc.hi.int64Value, lo: acc.lo.int64Value, gameHandle: gameHandle) else {
            return nil
        }
        return Tier7Access(trialToken: token)
    }

    static func activateOrContinue(hi: Int64, lo: Int64, gameHandle: Int?, activateAfterMulligan: Bool = false) async -> String? {
        await mutex.lock()
        let result = await activateOrContinueLocked(hi: hi, lo: lo, gameHandle: gameHandle, activateAfterMulligan: activateAfterMulligan)
        await mutex.unlock()
        return result
    }

    private static func activateOrContinueLocked(hi: Int64, lo: Int64, gameHandle: Int?, activateAfterMulligan: Bool) async -> String? {
        guard let gameHandle else {
            return nil
        }

        let current = persistedData
        if current.gameHandle == gameHandle {
            token = current.token
            return current.token
        }

        // Prevent using trials after mulligan phase
        if !canActivateNewTrial && !activateAfterMulligan {
            return nil
        }

        if _status == nil || _status?.trials_remaining == 0 {
            return nil
        }
        token = await HSReplayAPI.activatePlayerTrial(name: "tier7-overlay", hi: hi, lo: lo)?.token
        if let token {
            persistedData = Tier7TrialData(token: token, gameHandle: gameHandle)
            // HDT raises Tier7Trial.OnTrialActivated here; posting a notification
            // keeps the multicast semantics without giving this static type a
            // subscriber list of its own.
            NotificationCenter.default.post(name: Notification.Name(rawValue: Events.tier7_trial_activated), object: nil)
        }
        return token
    }

    static func update(hi: Int64, lo: Int64) async {
        if _status?.hours_til_next_reset ?? 0 < 2 {
            _status = nil
        }
        _status = await HSReplayAPI.getPlayerTrialStatus(name: "tier7-overlay", hi: hi, lo: lo)
    }

    // In-memory only, matching HDT's own Clear() - the persisted per-game
    // activation record survives so a relaunch mid-match continues the trial.
    static func clear() {
        _status = nil
        token = nil
    }
}
