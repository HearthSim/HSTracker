//
//  OfficialBuildTests.swift
//  HSTrackerTests
//
//  Created by Francisco Moraes on 9/18/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import XCTest
@testable import HSTracker

/// `AppDelegate.isTelemetryEnabled` gates Sentry and Mixpanel, and it has to fail in one
/// direction only: a silent failure in the code signing lookup would turn telemetry off
/// for every user rather than just for the forks it excludes, while a gate that stays
/// open reports our own development and test runs as if they were a user's. These tests
/// run injected into HSTracker.app, which carries our bundle id and our Developer ID
/// signature, so they sit on both sides of that line at once.
class OfficialBuildTests: XCTestCase {

    func testHostAppIsRecognizedAsOfficial() {
        XCTAssertTrue(AppDelegate.isOfficialBuild,
                      "The signed host app must be treated as official, or the guard "
                      + "disables crash reporting for real users")
    }

    func testHostAppCarriesTheOfficialBundleIdentifier() {
        XCTAssertEqual(Bundle.main.bundleIdentifier, "net.hearthsim.hstracker")
    }

    /// Being official is necessary but not sufficient: this very test run satisfies
    /// `isOfficialBuild`, and used to report its own fatal errors to Sentry as crashes
    /// from release 3.6.11+DEV.
    func testTelemetryIsOffWhileTestsAreRunning() {
        XCTAssertTrue(AppDelegate.isRunningTests,
                      "The XCTest environment marker has to be visible, or the gate that "
                      + "reads it never closes")
        XCTAssertFalse(AppDelegate.isTelemetryEnabled,
                       "A test run must not report into HearthSim's Sentry and Mixpanel")
    }

    /// Guards the other half of the gate, which a test run cannot observe directly: the
    /// repository's CFBundleVersion is the placeholder the release build overwrites.
    func testUnshippedBuildNumberIsRecognizedAsDevelopment() {
        XCTAssertEqual(Bundle.main.infoDictionary?["CFBundleVersion"] as? String, "DEV",
                       "Tests run against a locally built host app, which carries the "
                       + "placeholder build number from Info.plist")
        XCTAssertTrue(AppDelegate.isDevelopmentBuild)
    }
}
