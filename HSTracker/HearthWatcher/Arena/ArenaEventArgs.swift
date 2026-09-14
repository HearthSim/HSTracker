//
//  ArenaEventArgs.swift
//  HSTracker
//
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

/// A single picked card.
///
/// Deliberately not a `MirrorCard`: that is an ObjC class whose `_Nonnull`
/// properties are only ever populated by the mirror itself, so constructing one
/// here to represent a derived pick would hand Swift a non-optional `String` that
/// is actually nil.
struct ArenaPickedCard {
    let cardId: String
    let count: Int
    let premium: Int

    init(cardId: String, count: Int = 1, premium: Int = 0) {
        self.cardId = cardId
        self.count = count
        self.premium = premium
    }

    init(mirror: MirrorCard, count: Int? = nil) {
        self.cardId = mirror.cardId
        self.count = count ?? mirror.count.intValue
        self.premium = mirror.premium.intValue
    }
}

struct ChoicesChangedEventArgs {
    let choices: [MirrorCard]
    let deck: MirrorDeck
    let slot: Int
    let isUnderground: Bool
    let packages: [[MirrorCard]]?
}

struct CardPickedEventArgs {
    let picked: ArenaPickedCard
    let choices: [MirrorCard]
    let deck: MirrorDeck
    let slot: Int
    let isUnderground: Bool
    let pickedPackage: [MirrorCard]?
}

struct RedraftChoicesChangedEventArgs {
    let choices: [MirrorCard]
    let deck: MirrorDeck
    let redraftDeck: MirrorDeck
    let slot: Int
    let losses: Int
    let isUnderground: Bool
}

struct RedraftCardPickedEventArgs {
    let picked: ArenaPickedCard
    let choices: [MirrorCard]
    let deck: MirrorDeck
    let redraftDeck: MirrorDeck
    let slot: Int
    let losses: Int
    let isUnderground: Bool
}
