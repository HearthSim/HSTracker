//
//  CounterVisibilitySettingsTests.swift
//  HSTrackerTests
//
//  Created by Francisco Moraes on 9/23/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import XCTest
@testable import HSTracker

/// A match's game type cannot be set on a headless `Game`, so `BaseCounter.isVisible` is
/// only exercised here for its game-mode gate (outside any match). The override resolution
/// it delegates to is pure, so that is covered on its own.
class CounterVisibilitySettingsTests: HSTrackerTests {
    private let counterId = CthunCounter.counterId

    static var database: Database!

    override class func setUp() {
        super.setUp()
        database = Database()
        database.loadDatabase(splashscreen: nil, withLanguages: [.enUS])
    }

    override func setUp() {
        super.setUp()
        Settings.counterVisibilityOverrides = [:]
        CounterVisibilitySettings.instance.invalidate()
    }

    override func tearDown() {
        Settings.counterVisibilityOverrides = [:]
        CounterVisibilitySettings.instance.invalidate()
        super.tearDown()
    }

    private func makeGame() -> Game {
        return Game(hearthstoneRunState: HearthstoneRunState(isRunning: false, isActive: false))
    }

    // MARK: - Resolve

    func testResolveOverrideWinsAndAutoFallsBackToTheHeuristic() {
        let cases: [(CounterVisibility, Bool, Bool)] = [
            (.auto, true, true),
            (.auto, false, false),
            (.enabled, true, true),
            (.enabled, false, true),
            (.disabled, true, false),
            (.disabled, false, false)
        ]
        for (mode, heuristic, expected) in cases {
            XCTAssertEqual(CounterVisibilitySettings.resolve(mode, { heuristic }), expected,
                           "mode \(mode) with heuristic \(heuristic)")
        }
    }

    func testResolveOnlyEvaluatesTheHeuristicForAuto() {
        var calls = 0
        let heuristic: () -> Bool = { calls += 1; return true }

        _ = CounterVisibilitySettings.resolve(.enabled, heuristic)
        _ = CounterVisibilitySettings.resolve(.disabled, heuristic)
        XCTAssertEqual(calls, 0)

        _ = CounterVisibilitySettings.resolve(.auto, heuristic)
        XCTAssertEqual(calls, 1)
    }

    // MARK: - Storage

    func testUnknownCounterIsAuto() {
        let settings = CounterVisibilitySettings.instance

        XCTAssertEqual(settings.get("NotACounter", isPlayer: true), .auto)
        XCTAssertEqual(settings.get("NotACounter", isPlayer: false), .auto)
    }

    func testSidesAreIndependentAndStoredSparsely() {
        let settings = CounterVisibilitySettings.instance

        settings.set(counterId, isPlayer: false, .enabled)

        XCTAssertEqual(settings.get(counterId, isPlayer: false), .enabled)
        XCTAssertEqual(settings.get(counterId, isPlayer: true), .auto)
        XCTAssertEqual(Settings.counterVisibilityOverrides,
                       [counterId: [CounterVisibilitySettings.opponentKey: CounterVisibility.enabled.rawValue]])
    }

    func testSetBackToAutoRemovesOnlyThatSide() {
        let settings = CounterVisibilitySettings.instance

        settings.set(counterId, isPlayer: true, .disabled)
        settings.set(counterId, isPlayer: false, .enabled)
        settings.set(counterId, isPlayer: true, .auto)

        XCTAssertEqual(settings.get(counterId, isPlayer: true), .auto)
        XCTAssertEqual(settings.get(counterId, isPlayer: false), .enabled)
        XCTAssertEqual(Settings.counterVisibilityOverrides[counterId],
                       [CounterVisibilitySettings.opponentKey: CounterVisibility.enabled.rawValue])
    }

    func testBothSidesBackToAutoRemovesTheEntry() {
        let settings = CounterVisibilitySettings.instance

        settings.set(counterId, isPlayer: true, .disabled)
        settings.set(counterId, isPlayer: true, .auto)

        XCTAssertTrue(Settings.counterVisibilityOverrides.isEmpty)
        XCTAssertFalse(settings.hasAnyOverride)
    }

    func testSetEmptyCounterIdIsIgnored() {
        CounterVisibilitySettings.instance.set("", isPlayer: true, .enabled)

        XCTAssertTrue(Settings.counterVisibilityOverrides.isEmpty)
    }

    func testResetAllClearsKnownCountersAndKeepsEntriesFromNewerVersions() {
        let settings = CounterVisibilitySettings.instance
        settings.set(counterId, isPlayer: true, .enabled)
        // An entry this build knows nothing about, e.g. written by a newer version.
        var overrides = Settings.counterVisibilityOverrides
        overrides["FromTheFutureCounter"] = [CounterVisibilitySettings.playerKey: CounterVisibility.disabled.rawValue]
        Settings.counterVisibilityOverrides = overrides
        settings.invalidate()

        settings.resetAll()

        XCTAssertEqual(settings.get(counterId, isPlayer: true), .auto)
        XCTAssertEqual(Array(Settings.counterVisibilityOverrides.keys), ["FromTheFutureCounter"])
    }

    // MARK: - Counter ids

    func testCounterIdIsTheTypeName() {
        let game = makeGame()

        XCTAssertEqual(CthunCounter.counterId, "CthunCounter")
        XCTAssertEqual(CthunCounter(controlledByPlayer: true, game: game).counterId, "CthunCounter")
    }

    func testCatalogKnowsEveryCounterByItsHdtName() {
        let known = CounterCatalog.knownCounterIds

        for id in ["CthunCounter", "NextRefreshDemonFodderCounter", "ElementalExtraStatsCounter",
                   "ElementalTavernBuffStatsCounter", "UndeadBuffCounter"] {
            XCTAssertTrue(known.contains(id), id)
        }
        XCTAssertEqual(known.count, ReflectionHelper.getCounterClasses().count)
    }

    /// A counter whose portrait card is missing from the database, and that does not name
    /// itself, would show its type name in the settings pane instead of a real one.
    /// (DeitySizeCounter is one of the first kind: its portrait is a hero power, which
    /// `Cards.by` skips, but it has a localized name of its own.)
    func testEveryCounterHasARealDisplayName() {
        let descriptors = CounterCatalog.descriptors(game: makeGame())

        let showingTypeName = descriptors.filter { descriptor in
            descriptor.usesFallbackDisplayName
                && descriptor.displayName == descriptor.counterId.replacingOccurrences(of: "Counter", with: "")
        }

        XCTAssertEqual(descriptors.count, ReflectionHelper.getCounterClasses().count)
        XCTAssertEqual(showingTypeName.map { $0.counterId }, [])
    }

    /// Card id constants are partly hand-maintained here, so a typo'd or stale id would
    /// silently drop a card from a counter's deck check and tooltip.
    func testEveryCounterRelatedCardIsInTheCardDatabase() {
        let game = makeGame()
        var missing = [String]()
        for type in ReflectionHelper.getCounterClasses() {
            let counter = type.init(controlledByPlayer: true, game: game)
            for cardId in counter.relatedCards where Cards.any(byId: cardId) == nil {
                missing.append("\(counter.counterId): \(cardId)")
            }
        }

        XCTAssertEqual(missing, [])
    }

    // MARK: - Visibility

    func testForcedCounterStaysHiddenOutsideItsGameMode() {
        let counter = CthunCounter(controlledByPlayer: true, game: makeGame())
        CounterVisibilitySettings.instance.set(counterId, isPlayer: true, .enabled)

        XCTAssertEqual(counter.visibilityOverride, .enabled)
        XCTAssertFalse(counter.isVisible())
    }
}
