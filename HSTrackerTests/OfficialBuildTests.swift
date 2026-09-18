//
//  OfficialBuildTests.swift
//  HSTrackerTests
//
//  Created by Francisco Moraes on 9/18/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import XCTest
@testable import HSTracker

/// `AppDelegate.isOfficialBuild` gates Sentry and Mixpanel, so a silent failure in the
/// code signing lookup would turn telemetry off for every user rather than just for the
/// forks it is meant to exclude. These tests run injected into HSTracker.app, which is
/// signed with HearthSim's Developer ID, so the guard has to accept the host it runs in.
class OfficialBuildTests: XCTestCase {

    func testHostAppIsRecognizedAsOfficial() {
        XCTAssertTrue(AppDelegate.isOfficialBuild,
                      "The signed host app must be treated as official, or the guard "
                      + "disables crash reporting for real users")
    }

    func testHostAppCarriesTheOfficialBundleIdentifier() {
        XCTAssertEqual(Bundle.main.bundleIdentifier, "net.hearthsim.hstracker")
    }
}
