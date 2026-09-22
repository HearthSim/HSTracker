//
//  RelatedCardDescriptor.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/22/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

/// UI metadata for one row of the related cards settings pane: one card, however many
/// card ids it has (see `RelatedCardCatalog`).
///
/// Reads through to the `Card` instead of caching the name, so a card-language change is
/// picked up without rebuilding anything.
final class RelatedCardDescriptor {
    private let card: Card

    init(card: Card, cardIds: [String]) {
        self.card = card
        self.cardId = card.id
        self.cardIds = cardIds
    }

    /// The representative id: the one the override is stored under, and the one the row displays.
    let cardId: String

    /// Every registered id of this card, the representative first.
    let cardIds: [String]

    var cardIdsText: String { cardIds.joined(separator: ", ") }

    var displayName: String { card.name.isEmpty ? cardId : card.name }
}
