//
//  ArenaTrial.swift
//  HSTracker
//
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

/// Cached arena trial allowance for the signed-in Blizzard account.
///
/// Port of HDT's `HsReplay/ArenaTrial.cs`. Unlike the Battlegrounds trials there is
/// no token to activate: the server decides per deck, and `isDeckResumable` reports
/// whether the current draft is one it has already accepted.
@available(macOS 10.15, *)
final class ArenaTrial {
    static let instance = ArenaTrial()

    private var status: ArenaTrialStatus?
    private let lock = UnfairLock()

    private init() {}

    var remainingTrials: (starter: Int, recurring: Int)? {
        lock.around {
            guard let status else { return nil }
            return (status.starter_trials_remaining ?? 0, status.recurring_trials_remaining ?? 0)
        }
    }

    var maxRecurringTrials: Int? {
        lock.around { status?.max_recurring_trials }
    }

    /// Localized "resets in N days, M hours", or nil when the server didn't send a
    /// reset time (which it only does once the starter trials are used up).
    var timeRemaining: String? {
        let hours: Int? = lock.around { status?.hours_til_next_reset }
        guard let hours else { return nil }
        return String(format: String.localizedString("BattlegroundsPreLobby_Trial_ResetTimeRemaining_DaysHours", comment: ""),
                      hours / 24, hours % 24)
    }

    func isDeckResumable(_ deckId: Int64) -> Bool {
        lock.around { status?.resumable_deck_ids?.contains(deckId) ?? false }
    }

    func update(hi: Int64, lo: Int64) async {
        if lock.around({ status }) != nil { return }
        let result = await HSReplayAPI.getArenaTrialStatus(hi: hi, lo: lo)
        lock.around {
            if status == nil {
                status = result
            }
        }
    }

    func ensureLoaded(hi: Int64, lo: Int64) async {
        if lock.around({ status }) == nil {
            await update(hi: hi, lo: lo)
        }
    }

    /// Dropped whenever the draft moves on, so the next landing screen re-reads it.
    func clear() {
        lock.around { status = nil }
    }
}
