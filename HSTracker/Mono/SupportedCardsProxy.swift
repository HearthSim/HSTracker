//
//  SupportedCardsProxy.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/11/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

/// BobsBuddy.Utils.SupportedCards: compares a card against the Battlegrounds card
/// list BobsBuddy was built with (its embedded KnownBaconCards.xml).
class SupportedCardsProxy: MonoHandle, MonoClassInitializer {
    enum Result: Int32 {
        case supported = 1
        case unknownCard = 2
        case textChanged = 3
    }

    static var _class: OpaquePointer?
    static var _members = [String: OpaquePointer]()

    private static var _verifyCardIsSupported: OpaquePointer!
    private static var _cardFromId: OpaquePointer!

    static func initialize() {
        _class = MonoHelper.loadClass(ns: "BobsBuddy.Utils", name: "SupportedCards")
        _verifyCardIsSupported = MonoHelper.getMethod(_class, "VerifyCardIsSupported", 1)

        // VerifyCardIsSupported takes a HearthDb.Card, which BobsBuddy's own helper
        // looks up from the HearthDb that the simulation runs against.
        let hearthDbUtil = MonoHelper.loadClass(ns: "BobsBuddy", name: "HearthdbUtil")
        _cardFromId = MonoHelper.getMethod(hearthDbUtil, "CardFromID", 1)
    }

    /// A card id missing from BobsBuddy's HearthDb is reported as an unknown card:
    /// BobsBuddy could not summon it with the right stats either.
    static func verifyCardIsSupported(cardId: String) -> Result {
        guard let card = MonoHelper.invokeString(obj: MonoHandle(), method: _cardFromId, str: cardId) else {
            return .unknownCard
        }
        let params = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: 1)
        params[0] = UnsafeMutableRawPointer(card)
        let res = mono_runtime_invoke(_verifyCardIsSupported, nil, params, nil)
        params.deallocate()

        let value = mono_object_unbox(res)?.bindMemory(to: Int32.self, capacity: 1).pointee ?? 0
        return Result(rawValue: value) ?? .unknownCard
    }
}
