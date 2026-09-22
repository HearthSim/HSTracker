//
//  RelatedCardCatalog.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/22/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

/// Everything the related cards settings pane can configure: every card registered as an
/// `ICardWithRelatedCards`, with the ids of one card folded together.
///
/// There is no list of related cards here. `ReflectionHelper` already finds every
/// `ICardWithRelatedCards`, and this reads from it, so adding a related card needs
/// nothing in this file.
///
/// A card often exists under several ids (its Core, Vanilla and Caverns of Time reprints,
/// or a token twin). Those are one card to the user, so they share one row and one
/// override. There is no canonical-card id to group by, so a card's identity here is its
/// name, type and stats: that keeps reprints together while same-named cards that really
/// differ (a hero power and a minion, or a minion and the differently-statted token it
/// becomes) stay apart.
enum RelatedCardCatalog {
    private static let lock = NSLock()

    private static var _descriptors: [RelatedCardDescriptor]?
    private static var _missingCardIds: [String]?
    private static var _variantsById: [String: [String]]?
    private static var _knownCardIds: Set<String>?

    /// Persistence keys of every configurable related card, one per registered id.
    /// Independent of the card database, so it can be asked for without the catalog (or
    /// the database) being ready.
    static var knownCardIds: Set<String> {
        lock.lock()
        defer { lock.unlock() }
        if let known = _knownCardIds {
            return known
        }
        var known = Set<String>()
        for type in ReflectionHelper.getRelatedClases() {
            let cardId = type.init().getCardId()
            if !cardId.isEmpty {
                known.insert(cardId)
            }
        }
        _knownCardIds = known
        return known
    }

    /// One descriptor per card, however many ids it has.
    static var descriptors: [RelatedCardDescriptor] {
        ensureBuilt()
        lock.lock()
        defer { lock.unlock() }
        return _descriptors ?? []
    }

    /// Registered card ids the card database could not resolve. Always empty in a healthy
    /// build; the guard test asserts this, which is what stops the other catalog
    /// assertions passing vacuously when a card is silently skipped below.
    static var missingCardIds: [String] {
        ensureBuilt()
        lock.lock()
        defer { lock.unlock() }
        return _missingCardIds ?? []
    }

    /// All ids that are the same card as `cardId`, itself included and the representative
    /// first. An id the catalog does not know is just itself.
    static func getVariantIds(_ cardId: String) -> [String] {
        ensureBuilt()
        lock.lock()
        defer { lock.unlock() }
        return _variantsById?[cardId] ?? [cardId]
    }

    private static func variantKey(_ card: Card) -> String {
        return "\(card.name)|\(card.type)|\(card.cost)|\(card.attack)|\(card.health)"
    }

    private static func ensureBuilt() {
        lock.lock()
        let built = _descriptors != nil
        lock.unlock()
        if !built {
            build()
        }
    }

    private static func build() {
        var missing = [String]()
        var cards = [Card]()

        // Ordinal order so the result (and which id represents a card) never depends on
        // the order reflection happens to return types in.
        for cardId in knownCardIds.sorted(by: { $0 < $1 }) {
            guard let card = Cards.any(byId: cardId) else {
                logger.error("Could not find related card \(cardId) in the card database")
                missing.append(cardId)
                continue
            }
            cards.append(card)
        }

        var groups = [String: [Card]]()
        for card in cards {
            groups[variantKey(card), default: []].append(card)
        }

        var descriptors = [RelatedCardDescriptor]()
        var variantsById = [String: [String]]()

        for group in groups.values {
            // A collectible version is the one worth showing; ties fall back to the id
            // for stability.
            let ordered = group.sorted { lhs, rhs in
                if lhs.collectible != rhs.collectible {
                    return lhs.collectible
                }
                return lhs.id < rhs.id
            }
            let ids = ordered.map { $0.id }

            descriptors.append(RelatedCardDescriptor(card: ordered[0], cardIds: ids))
            for id in ids {
                variantsById[id] = ids
            }
        }

        lock.lock()
        // Ordering is deliberately not applied to the descriptors: the display name is
        // live, so a card-language change would leave a cached order stale. The settings
        // pane sorts when it binds.
        _missingCardIds = missing
        _variantsById = variantsById
        _descriptors = descriptors
        lock.unlock()
    }

    /// Drops the cached card data so the next read rebuilds it. Used when the card
    /// language changes, which is the one thing that invalidates a descriptor.
    static func invalidate() {
        lock.lock()
        _descriptors = nil
        _missingCardIds = nil
        _variantsById = nil
        lock.unlock()
    }
}
