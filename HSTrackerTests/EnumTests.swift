//
//  EnumTests.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 5/05/17.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import XCTest
@testable import HSTracker

class EnumTests: HSTrackerTests {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testLanguages() {
        let locales: [Language.Hearthstone] = [.deDE, .enUS, .esES, .esMX,
                                               .frFR, .itIT, .koKR, .plPL,
                                               .ptBR, .ruRU, .zhCN, .zhTW,
                                               .jaJP, .thTH].sorted(by: {
            $0.rawValue.localizedCaseInsensitiveCompare($1.rawValue) == ComparisonResult.orderedAscending
        })

        let languages: [Language.Hearthstone] = Array(Language.Hearthstone.allCases).sorted(by: {
            $0.rawValue.localizedCaseInsensitiveCompare($1.rawValue) == ComparisonResult.orderedAscending
        })
        XCTAssertEqual(languages.count, 14, "There are 14 locales")
        XCTAssertEqual(languages, locales, "Sorting locale is not the same")
    }

    /// The enums below are indexed by a raw number that comes straight from
    /// Hearthstone, so every one of them can be handed a value from a client
    /// that knows more cases than we do. Indexing has to return nil rather than
    /// trap: in issue #1445 the Black Market scene added in 36.6 arrived as mode
    /// 29, ran off the end of `Mode.allCases` and crashed HSTracker on launch.
    func testGameIndexedEnumsDoNotTrapOnUnknownValues() {
        XCTAssertNil(Mode.allCases[safeIndex: Mode.allCases.count],
                     "A scene mode newer than ours must not be indexable")
        XCTAssertNil(Mode.allCases[safeIndex: -1])
        XCTAssertNil(Race.allCases[safeIndex: Race.allCases.count])
        XCTAssertNil(CardClass.allCases[safeIndex: CardClass.allCases.count])
        XCTAssertNil(Rarity.allCases[safeIndex: Rarity.allCases.count])

        XCTAssertEqual(Mode.allCases[safeIndex: 0], .invalid)
        XCTAssertEqual(Mode.allCases[safeIndex: Mode.allCases.count] ?? .invalid, .invalid,
                       "An unknown scene mode degrades to .invalid, matching the "
                       + "unnamed enum value HDT's C# cast produces")
    }

    /// Bounds checking only saves us from cases Blizzard *appends*. The mapping
    /// is positional, so a case inserted into the middle of this enum silently
    /// shifts every scene after it and HSTracker reacts to the wrong screen
    /// without any crash to point at it. New client scenes go on the end.
    func testModeOrderMatchesTheClient() {
        XCTAssertEqual(Mode.allCases.map { $0.rawValue }, [
            "invalid",
            "startup",
            "login",
            "hub",
            "gameplay",
            "collectionmanager",
            "packopening",
            "tournament",
            "friendly",
            "fatal_error",
            "draft",
            "credits",
            "reset",
            "adventure",
            "tavern_brawl",
            "bacon",
            "game_mode",
            "pvp_dungeon_run",
            "bacon_collection",
            "lettuce_village",
            "lettuce_bounty_board",
            "lettuce_map",
            "lettuce_play",
            "lettuce_collection",
            "lettuce_coop",
            "lettuce_friendly",
            "lettuce_bounty_team_select",
            "lettuce_pack_opening",
            "lucky_draw",
            "black_market"
        ], "Mode is indexed by the client's scene number - only append to it")
    }
}
