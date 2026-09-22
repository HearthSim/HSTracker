//
//  RelatedCardVisibilitySettings.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/22/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

/// Reads and writes the per-card overrides for the opponent's "Related Cards" list.
///
/// The list is rebuilt on every opponent card update and looks up every registered
/// related card, so lookups have to be O(1): the stored overrides are kept in a
/// dictionary that is reloaded only when something actually changes.
///
/// Storage is sparse: an entry only exists while the card is non-Auto. A card with no
/// entry resolves to Auto, which is what lets a newly added related card work without any
/// config migration. HDT keeps a list of `RelatedCardVisibilityOverride` records in its
/// XML config, each with a card id and a side, so a player side can be added later
/// without changing the file format; HSTracker stores the same thing as a card id to
/// visibility map in the user defaults, which is one key per card for the same reason.
final class RelatedCardVisibilitySettings {
    static let instance = RelatedCardVisibilitySettings()

    private init() {
    }

    private var _lookup: [String: RelatedCardVisibility]?

    private var lookup: [String: RelatedCardVisibility] {
        if let lookup = _lookup {
            return lookup
        }
        var lookup = [String: RelatedCardVisibility]()
        for (cardId, raw) in Settings.relatedCardVisibilityOverrides {
            if !cardId.isEmpty, let value = RelatedCardVisibility(rawValue: raw), value != .auto {
                lookup[cardId] = value
            }
        }
        _lookup = lookup
        return lookup
    }

    func invalidate() {
        _lookup = nil
    }

    /// The override for a card, which is shared by every id of that card (see
    /// `RelatedCardCatalog.getVariantIds`). Any id's entry counts, not just the
    /// representative's, so a card that later gains another id, or an entry saved before
    /// an id joined its group, keeps applying.
    func getOpponent(_ cardId: String) -> RelatedCardVisibility {
        // Checked first: it is the common case (nothing customised), and it keeps the
        // catalog, and with it the card database, out of the picture for anyone who never
        // used this setting.
        if lookup.isEmpty {
            return .auto
        }

        for id in RelatedCardCatalog.getVariantIds(cardId) {
            if let value = lookup[id] {
                return value
            }
        }
        return .auto
    }

    /// Sets the override for every id of the card. It is stored once, under the
    /// representative id; entries under the card's other ids are folded into it, which
    /// also cleans up after the group changed shape.
    func setOpponent(_ cardId: String, _ value: RelatedCardVisibility) {
        if cardId.isEmpty {
            return
        }

        let ids = RelatedCardCatalog.getVariantIds(cardId)
        var overrides = Settings.relatedCardVisibilityOverrides
        var changed = false

        for other in ids.dropFirst() where overrides.removeValue(forKey: other) != nil {
            changed = true
        }

        let representative = ids[0]
        if value == .auto {
            if overrides.removeValue(forKey: representative) != nil {
                changed = true
            }
        } else if overrides[representative] != value.rawValue {
            overrides[representative] = value.rawValue
            changed = true
        }

        if !changed {
            return
        }

        Settings.relatedCardVisibilityOverrides = overrides
        invalidate()
    }

    /// Final decision for one card: the user's override wins, otherwise the card's own
    /// heuristic. Legality is deliberately not part of this - it is a hard gate the caller
    /// applies first, so a forced card can still never be one that cannot exist in the
    /// current format.
    static func resolve(_ mode: RelatedCardVisibility, _ heuristic: () -> Bool) -> Bool {
        switch mode {
        case .disabled:
            return false
        case .enabled:
            return true
        case .auto:
            return heuristic()
        }
    }

    var hasAnyOverride: Bool { !lookup.isEmpty }

    func resetAll() {
        let known = RelatedCardCatalog.knownCardIds
        var overrides = Settings.relatedCardVisibilityOverrides
        let before = overrides.count
        overrides = overrides.filter { !$0.key.isEmpty && !known.contains($0.key) }
        if overrides.count == before {
            return
        }

        Settings.relatedCardVisibilityOverrides = overrides
        invalidate()
    }
}
