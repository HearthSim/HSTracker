//
//  HSTrackerTests.swift
//  HSTrackerTests
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import XCTest
import RealmSwift

@testable import HSTracker

class HSTrackerTests: XCTestCase {

    override func setUp() {
        super.setUp()

        // initialize test realm's database
        Realm.Configuration.defaultConfiguration.inMemoryIdentifier = self.name
    }

    override func tearDown() {
        super.tearDown()
    }

}
