//
//  ArenaPackagesManager.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/7/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

/// Ports HDT's `Hearthstone/Arena/ArenaPackagesManager.cs`.
///
/// Arena rotations group a legendary with the cards that only appear alongside it.
/// Seeing one of those package-only cards in the opponent's deck therefore reveals
/// the whole group, which is what the tracker's Arenasmith lens shows.
///
/// HDT's `UpdateMetrics` is not ported: HSTracker has no ValueMoments layer to
/// record `ArenaShowedOpponentPackage` into.
class ArenaPackagesManager {
    /// Guards both dictionaries: `updatePackages()` writes from a detached task
    /// while `getOpponentsPackageCards` reads from the main thread on every
    /// opponent tracker update.
    private let lock = NSLock()
    private var packagesByKeyCard = [String: [String]]()
    private var packagesKeyByPackageOnlyCard = [String: String]()

    @available(macOS 10.15.0, *)
    func updatePackages() async {
        guard let data = await fetchPackages()?.data else {
            lock.lock()
            packagesByKeyCard.removeAll()
            packagesKeyByPackageOnlyCard.removeAll()
            lock.unlock()
            return
        }

        lock.lock()
        packagesByKeyCard = data.packages_by_key_card ?? [:]
        packagesKeyByPackageOnlyCard = data.packages_from_package_only_cards ?? [:]
        lock.unlock()
    }

    /// Ports the routing in HDT's `ApiWrapper.GetArenaPackages()`: a signed-in
    /// account goes through OAuth, everybody else through the unauthenticated
    /// endpoint, and only for a deck the server has accepted for a trial.
    @available(macOS 10.15.0, *)
    private func fetchPackages() async -> ArenaPackages? {
        if HSReplayAPI.accountData != nil && HSReplayAPI.isFullyAuthenticated {
            return await HSReplayAPI.getArenaPackages()
        }

        guard let deckId = MirrorHelper.getArenaInfo()?.deck.id.int64Value,
              let accountId = MirrorHelper.getAccountId() else {
            return nil
        }
        let hi = accountId.hi.int64Value
        let lo = accountId.lo.int64Value

        await ArenaTrial.instance.ensureLoaded(hi: hi, lo: lo)
        guard ArenaTrial.instance.isDeckResumable(deckId) else {
            logger.info("Current deck is not registered for trials, aborting")
            return nil
        }

        return await HSReplayAPI.getArenaPackages(deckId: deckId, accountLo: lo,
                                                  playerRegion: Helper.getRegion(hi: hi).rawValue)
    }

    /// Returns the package key card and the full group - key card first - for the
    /// first package-only card found in the opponent's deck, or `(nil, [])` when
    /// nothing matches.
    func getOpponentsPackageCards(_ opponentsDecklist: [Card]) -> (Card?, [Card]) {
        lock.lock()
        let byKeyCard = packagesByKeyCard
        let keyByPackageOnlyCard = packagesKeyByPackageOnlyCard
        lock.unlock()

        if byKeyCard.isEmpty || keyByPackageOnlyCard.isEmpty {
            return (nil, [])
        }

        for card in opponentsDecklist where !card.isCreated {
            guard let packageKey = keyByPackageOnlyCard[card.id] else {
                continue
            }
            guard let package = byKeyCard[packageKey] else {
                logger.error("Missing Package for \(packageKey)")
                continue
            }
            guard let keyCard = Cards.by(cardId: packageKey) else {
                logger.error("Unknown package key card \(packageKey)")
                continue
            }

            return (keyCard, [keyCard] + package.compactMap { Cards.by(cardId: $0) })
        }

        return (nil, [])
    }
}
