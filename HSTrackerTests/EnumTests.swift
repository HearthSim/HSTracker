//
//  EnumTests.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 5/05/17.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import XCTest
@testable import HSTracker

class EnumTests: XCTestCase {

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

        let languages: [Language.Hearthstone] = Array(Language.Hearthstone.cases()).sorted(by: {
            $0.rawValue.localizedCaseInsensitiveCompare($1.rawValue) == ComparisonResult.orderedAscending
        })
        XCTAssertEqual(languages.count, 14, "There are 14 locales")
        XCTAssertEqual(languages, locales, "Sorting locale is not the same")
    }
}
