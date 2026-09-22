//
//  RelatedCardVisibilitySettingsTests.swift
//  HSTrackerTests
//
//  Created by Francisco Moraes on 9/22/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import XCTest
@testable import HSTracker

/// The runtime chokepoint (`RelatedCardsManager.getCardsOpponentMayHave`) is not exercised
/// end to end here: running the real heuristics reads the live `Game`, which cannot be
/// built headless. The override resolution it delegates to is pure, so that is what is
/// covered instead.
class RelatedCardVisibilitySettingsTests: HSTrackerTests {
    private let cardId = CardIds.Collectible.DemonHunter.JaceDarkweaver

    // Arfus: the original and the Core reprint are one card with two ids.
    private let arfusOriginal = CardIds.Collectible.Neutral.Arfus
    private let arfusCore = CardIds.Collectible.Neutral.ArfusCorePlaceholder

    static var database: Database!

    override class func setUp() {
        super.setUp()
        database = Database()
        database.loadDatabase(splashscreen: nil, withLanguages: [.enUS])
    }

    override func setUp() {
        super.setUp()
        Settings.relatedCardVisibilityOverrides = [:]
        RelatedCardVisibilitySettings.instance.invalidate()
    }

    override func tearDown() {
        Settings.relatedCardVisibilityOverrides = [:]
        RelatedCardVisibilitySettings.instance.invalidate()
        super.tearDown()
    }

    // MARK: - Resolve

    func testResolveOverrideWinsAndAutoFallsBackToTheHeuristic() {
        let cases: [(RelatedCardVisibility, Bool, Bool)] = [
            (.auto, true, true),
            (.auto, false, false),
            (.enabled, true, true),
            (.enabled, false, true),
            (.disabled, true, false),
            (.disabled, false, false)
        ]
        for (mode, heuristic, expected) in cases {
            XCTAssertEqual(RelatedCardVisibilitySettings.resolve(mode, { heuristic }), expected,
                           "mode \(mode) with heuristic \(heuristic)")
        }
    }

    func testResolveOnlyEvaluatesTheHeuristicForAuto() {
        // Heuristics read game state, so an explicit choice must not pay for (or depend
        // on) one.
        var calls = 0
        let heuristic: () -> Bool = { calls += 1; return true }

        _ = RelatedCardVisibilitySettings.resolve(.enabled, heuristic)
        _ = RelatedCardVisibilitySettings.resolve(.disabled, heuristic)
        XCTAssertEqual(calls, 0)

        _ = RelatedCardVisibilitySettings.resolve(.auto, heuristic)
        XCTAssertEqual(calls, 1)
    }

    // MARK: - Storage

    func testUnknownCardIsAuto() {
        XCTAssertEqual(RelatedCardVisibilitySettings.instance.getOpponent("NOT_A_CARD"), .auto)
    }

    func testSetStoresSparsely() {
        let settings = RelatedCardVisibilitySettings.instance

        settings.setOpponent(cardId, .enabled)

        XCTAssertEqual(settings.getOpponent(cardId), .enabled)
        XCTAssertEqual(Settings.relatedCardVisibilityOverrides.count, 1)
        XCTAssertEqual(Settings.relatedCardVisibilityOverrides[cardId], RelatedCardVisibility.enabled.rawValue)
    }

    func testSetBackToAutoRemovesTheEntry() {
        let settings = RelatedCardVisibilitySettings.instance

        settings.setOpponent(cardId, .disabled)
        settings.setOpponent(cardId, .auto)

        XCTAssertEqual(settings.getOpponent(cardId), .auto)
        XCTAssertTrue(Settings.relatedCardVisibilityOverrides.isEmpty)
        XCTAssertFalse(settings.hasAnyOverride)
    }

    func testSetEmptyCardIdIsIgnored() {
        RelatedCardVisibilitySettings.instance.setOpponent("", .enabled)

        XCTAssertTrue(Settings.relatedCardVisibilityOverrides.isEmpty)
    }

    func testResetAllClearsKnownCardsAndKeepsEntriesFromNewerVersions() {
        let settings = RelatedCardVisibilitySettings.instance
        settings.setOpponent(cardId, .enabled)
        // An entry this build knows nothing about, e.g. written by a newer version.
        var overrides = Settings.relatedCardVisibilityOverrides
        overrides["FROM_THE_FUTURE"] = RelatedCardVisibility.disabled.rawValue
        Settings.relatedCardVisibilityOverrides = overrides
        settings.invalidate()

        settings.resetAll()

        XCTAssertEqual(settings.getOpponent(cardId), .auto)
        XCTAssertEqual(Settings.relatedCardVisibilityOverrides.count, 1)
        XCTAssertEqual(Settings.relatedCardVisibilityOverrides["FROM_THE_FUTURE"],
                       RelatedCardVisibility.disabled.rawValue)
    }

    // MARK: - Catalog

    func testCatalogListsRegisteredRelatedCardsWithoutTheDefaultPlaceholder() {
        let known = RelatedCardCatalog.knownCardIds

        XCTAssertTrue(known.contains(cardId))
        XCTAssertFalse(known.contains(""))
    }

    /// Guards the other catalog assertions from passing vacuously: a related card the card
    /// database cannot resolve is skipped, which would silently shrink every assertion
    /// above.
    func testCatalogResolvesEveryRegisteredCard() {
        XCTAssertEqual(RelatedCardCatalog.missingCardIds, [])
    }

    func testCatalogFoldsTheIdsOfOneCardIntoOneRow() {
        let rows = RelatedCardCatalog.descriptors.filter { $0.cardIds.contains(arfusOriginal) }

        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(Set(rows.first?.cardIds ?? []), Set([arfusOriginal, arfusCore]))
        XCTAssertEqual(rows.first?.cardId, rows.first?.cardIds.first)
    }

    func testCatalogEveryRegisteredCardIsInExactlyOneRow() {
        let allIds = RelatedCardCatalog.descriptors.flatMap { $0.cardIds }

        XCTAssertEqual(allIds.count, Set(allIds).count)
        XCTAssertEqual(Set(allIds), RelatedCardCatalog.knownCardIds)
        XCTAssertLessThan(RelatedCardCatalog.descriptors.count, RelatedCardCatalog.knownCardIds.count)
    }

    func testCatalogKeepsSameNamedCardsThatReallyDifferApart() {
        // The minion and the token it becomes share a name but are not the same card.
        let geist = CardIds.Collectible.Deathknight.ToysnatchingGeist
        let geistToken = CardIds.NonCollectible.Deathknight.ToysnatchingGeist_ToysnatchingGeistToken

        XCTAssertFalse(RelatedCardCatalog.getVariantIds(geist).contains(geistToken))
    }

    // MARK: - Variant ids

    func testOverrideAppliesToEveryIdOfTheCard() {
        let settings = RelatedCardVisibilitySettings.instance

        settings.setOpponent(arfusOriginal, .enabled)

        XCTAssertEqual(settings.getOpponent(arfusOriginal), .enabled)
        XCTAssertEqual(settings.getOpponent(arfusCore), .enabled)
        XCTAssertEqual(Settings.relatedCardVisibilityOverrides.count, 1)
    }

    func testOverrideIsStoredUnderTheRepresentativeWhicheverIdWasUsed() {
        let settings = RelatedCardVisibilitySettings.instance
        let representative = RelatedCardCatalog.getVariantIds(arfusOriginal)[0]
        let other = representative == arfusOriginal ? arfusCore : arfusOriginal

        settings.setOpponent(other, .disabled)

        XCTAssertEqual(Array(Settings.relatedCardVisibilityOverrides.keys), [representative])
    }

    func testSetBackToAutoClearsEveryIdOfTheCard() {
        let settings = RelatedCardVisibilitySettings.instance

        settings.setOpponent(arfusOriginal, .enabled)
        settings.setOpponent(arfusCore, .auto)

        XCTAssertTrue(Settings.relatedCardVisibilityOverrides.isEmpty)
        XCTAssertEqual(settings.getOpponent(arfusOriginal), .auto)
    }

    /// e.g. saved before a reprint joined the card, or when another id represented it.
    func testEntryUnderANonRepresentativeIdStillAppliesAndIsFoldedOnTheNextChange() {
        let settings = RelatedCardVisibilitySettings.instance
        let representative = RelatedCardCatalog.getVariantIds(arfusOriginal)[0]
        let other = representative == arfusOriginal ? arfusCore : arfusOriginal

        Settings.relatedCardVisibilityOverrides = [other: RelatedCardVisibility.enabled.rawValue]
        settings.invalidate()

        XCTAssertEqual(settings.getOpponent(representative), .enabled)

        settings.setOpponent(representative, .disabled)

        XCTAssertEqual(Array(Settings.relatedCardVisibilityOverrides.keys), [representative])
        XCTAssertEqual(settings.getOpponent(other), .disabled)
    }
}
