//
//  BattlegroundsInspirationViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/21/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation
import SwiftUI

// Mirrors HDT's BattlegroundsInspirationViewModel: the Tier7 Inspiration panel,
// which answers "what did first-place boards holding this minion look like?".
//
// Entered from three places, all of which call setKeyMinion then show():
//   - the per-card button on a minion browser row (BattlegroundsCardsGroupView)
//   - "Show Example Lineups" on a comp guide (CompGuideDetailView)
//   - a minion or hero power inside the panel itself, which re-queries around
//     whatever was clicked
//
// isShown lives here rather than in an OverlayElementBehavior as it does in
// HDT - the SwiftUI overlay has no such thing, and RootOverlayView reads this
// directly.
@available(macOS 10.15, *)
final class BattlegroundsInspirationViewModel: ObservableObject {
    // Four lineups per page, as in HDT's Games getter.
    static let gamesPerPage = 4
    // HDT takes the first 20 lineups off the response.
    private static let maxGames = 20

    @Published private(set) var isShown = false
    @Published private(set) var isLoadingData = false
    @Published private(set) var titleText = ""
    @Published private(set) var mmrPercentile = 5
    @Published private(set) var page = 1

    // Every loaded lineup; `pagedGames` is the slice the panel renders.
    @Published private(set) var allGames: [BattlegroundsInspirationGameViewModel]?

    var pagedGames: [BattlegroundsInspirationGameViewModel] {
        guard let allGames else { return [] }
        let start = (page - 1) * Self.gamesPerPage
        guard start < allGames.count else { return [] }
        return Array(allGames[start ..< min(start + Self.gamesPerPage, allGames.count)])
    }

    struct PageButton: Identifiable {
        let page: Int
        let isActive: Bool
        var id: Int { page }
    }

    // HDT only populates Pages when there is more than one, so a single-page
    // result shows no pager at all.
    var pageButtons: [PageButton] {
        let count = Int(ceil(Double(allGames?.count ?? 0) / Double(Self.gamesPerPage)))
        guard count > 1 else { return [] }
        return (1...count).map { PageButton(page: $0, isActive: $0 == page) }
    }

    var mmrText: String {
        String(format: Self.localized("BattlegroundsInspiration_Description_MMR",
                                      fallback: "Games from Top %d%% MMR"), mmrPercentile)
    }

    // Whether the panel has ever been asked for a lineup this match. HDT uses
    // it to decide if the top-bar button should come back after the panel is
    // closed - there is nothing to re-open before the first request.
    var hasBeenActivated: Bool { !lastRequestKeyDbfIds.isEmpty }

    var hasNoGames: Bool { (allGames?.isEmpty ?? true) && !isLoadingData }

    private var lastRequestKeyDbfIds = [Int]()
    private var lastRequestBoardDbfIds = [Int]()

    // The board sent alongside the key minion is the player's live board while
    // shopping, and the board as it stood when shopping ended once combat
    // starts - so opening the panel mid-combat still describes the lineup the
    // player actually built.
    private var isInShopping = true
    private var endOfShoppingBoardState = [Int]()

    // MARK: - Panel visibility

    @MainActor
    func show() {
        guard AppDelegate.instance().coreManager.game.isBattlegroundsMatch() else { return }
        isShown = true
    }

    @MainActor
    func close() {
        isShown = false
    }

    // MARK: - Requests

    // Convenience overload matching HDT's `SetKeyMinion(params Card?[])`, which
    // titles the panel after the first card.
    @MainActor
    func setKeyMinion(_ cards: [Card]) {
        setKeyMinion(title: cards.first?.name ?? "", cards: cards)
    }

    @MainActor
    func setKeyMinion(title: String, cards: [Card]) {
        if cards.isEmpty {
            lastRequestKeyDbfIds.removeAll()
            return
        }

        // Always request the normal dbf ids: the user may have incidentally
        // clicked a tripled minion. HDT reads Cards.TripleToNormalDbfIds;
        // HSTracker carries the same link on the card itself, as the base
        // minion a triple was built from.
        let keyDbfIds = cards.map { card in
            card.baconTripledBaseMinionId > 0 ? card.baconTripledBaseMinionId : card.dbfId
        }

        let game = AppDelegate.instance().coreManager.game
        let boardDbfIds = isInShopping
            ? game.player.board.filter { $0.isMinion }.map { $0.card.dbfId }.sorted()
            : endOfShoppingBoardState

        // Re-clicking the same minion with the same board is a no-op, so the
        // panel keeps whatever it already loaded instead of re-querying.
        if keyDbfIds == lastRequestKeyDbfIds && boardDbfIds == lastRequestBoardDbfIds {
            return
        }
        lastRequestKeyDbfIds = keyDbfIds
        lastRequestBoardDbfIds = boardDbfIds

        titleText = title
        allGames = nil
        isLoadingData = true
        // Duos pools are shallower, so the sample is widened to the top 10%.
        mmrPercentile = game.isBattlegroundsDuosMatch() ? 10 : 5
        page = 1

        Task { @MainActor in
            let response = await makeRequest(keyDbfIds: keyDbfIds, boardDbfIds: boardDbfIds)
            allGames = response?.data.lineups
                .prefix(Self.maxGames)
                .map { BattlegroundsInspirationGameViewModel($0) }
            isLoadingData = false
        }
    }

    @MainActor
    func setPage(_ page: Int) {
        self.page = page
    }

    private func makeRequest(keyDbfIds: [Int], boardDbfIds: [Int]) async -> BattlegroundsInspiration? {
        let userOwnsTier7 = HSReplayAPI.accountData?.is_tier7 ?? false
        // HDT bails on `RemainingTrials == 0` alone, which also blocks the
        // request when the trial being spent is the one already active for this
        // match - the exact case the panel is most likely to be opened in. The
        // extra token check keeps an active trial working.
        if !userOwnsTier7 && (Tier7Trial.remainingTrials ?? 0) == 0 && Tier7Trial.token == nil {
            return nil
        }

        let game = AppDelegate.instance().coreManager.game
        guard let races = game.availableRaces, races.count == 5 else {
            logger.error("Inspiration: invalid number of races: \(game.availableRaces?.count ?? 0)")
            return nil
        }
        guard boardDbfIds.count <= 7 else {
            logger.error("Inspiration: invalid number of board dbf ids: \(boardDbfIds.count)")
            return nil
        }

        // Assembled before touching the trial system, as in HDT - no point
        // spending a trial on a request that cannot be built.
        let parameters = BattlegroundsInspirationParams(
            minion_types: races.compactMap { Race.allCases.firstIndex(of: $0) },
            key_card_dbf_ids: keyDbfIds,
            game_type: BnetGameType.getBnetGameType(gameType: game.currentGameType, format: game.currentFormat).rawValue,
            lineup_dbf_ids: boardDbfIds
        )

        if userOwnsTier7 {
            return await HSReplayAPI.getBattlegroundsInspiration(parameters: parameters)
        }

        guard let acc = MirrorHelper.getAccountId() else {
            logger.error("Inspiration: unable to get account id for trial token")
            return nil
        }
        guard let token = await Tier7Trial.activate(hi: acc.hi.int64Value, lo: acc.lo.int64Value) else {
            logger.error("Inspiration: unable to get trial token")
            return nil
        }
        return await HSReplayAPI.getBattlegroundsInspiration(token: token, parameters: parameters)
    }

    // MARK: - Match lifecycle

    func onShoppingStart() {
        isInShopping = true
    }

    func onShoppingEnd() {
        isInShopping = false
        let game = AppDelegate.instance().coreManager.game
        endOfShoppingBoardState = game.player.board.filter { $0.isMinion }.map { $0.card.dbfId }
    }

    @MainActor
    func reset() {
        isShown = false
        allGames = nil
        page = 1
        titleText = ""
        isLoadingData = false
        isInShopping = true
        lastRequestKeyDbfIds = []
        lastRequestBoardDbfIds = []
        endOfShoppingBoardState = []
    }

    // HSTracker has no string catalog for these HDT keys, so each carries the
    // English master's text as a fallback - the same arrangement
    // BattlegroundsMinionType uses for the race names.
    static func localized(_ key: String, fallback: String) -> String {
        let value = String.localizedString(key, comment: "")
        return value == key ? fallback : value
    }
}
