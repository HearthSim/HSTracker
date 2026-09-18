//
//  OverlayCanvasGeometryTests.swift
//  HSTrackerTests
//
//  Created by Francisco Moraes on 9/18/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import SwiftUI
import XCTest
@testable import HSTracker

/// The overlay canvas can be measured before Hearthstone's own frame is known,
/// and the zero width that comes back used to travel all the way into SwiftUI's
/// layout engine as a NaN position, which traps the process.
class OverlayCanvasGeometryTests: HSTrackerTests {

    // MARK: - getScaledXPos

    /// The ordinary case: a 16:9 client, where the 4:3 play area is inset by
    /// half the leftover width.
    func testScaledXPosOnARealWindow() {
        let width: CGFloat = 1920
        let ratio = (4.0 / 3.0) / (width / 1080)
        XCTAssertEqual(SizeHelper.getScaledXPos(0.5, width: width, ratio: ratio), 960, accuracy: 0.001)
        XCTAssertEqual(SizeHelper.getScaledXPos(0, width: width, ratio: ratio), 240, accuracy: 0.001)
    }

    /// A zero width makes every caller's ratio infinite, and both terms of the
    /// formula 0 * inf. The result has to stay finite.
    func testScaledXPosOnAZeroWidthWindow() {
        let x = SizeHelper.getScaledXPos(0.5, width: 0, ratio: 1440 / 0)
        XCTAssertTrue(x.isFinite)
        XCTAssertEqual(x, 0)
    }

    /// A zero width *and* a zero height gives 0 / 0, so the ratio arrives as a
    /// NaN rather than an infinity.
    func testScaledXPosOnANaNRatio() {
        let ratio = (4.0 / 3.0) / (CGFloat(0) / CGFloat(0))
        XCTAssertTrue(ratio.isNaN)
        XCTAssertTrue(SizeHelper.getScaledXPos(0.5, width: 0, ratio: ratio).isFinite)
    }

    /// A non-finite width has no sensible position inside it at all.
    func testScaledXPosOnANonFiniteWidth() {
        XCTAssertTrue(SizeHelper.getScaledXPos(0.5, width: CGFloat.infinity, ratio: 1).isFinite)
        XCTAssertTrue(SizeHelper.getScaledXPos(0.5, width: CGFloat.nan, ratio: 1).isFinite)
    }

    // MARK: - isUsableCanvas

    func testUsableCanvasAcceptsARealMeasurement() {
        XCTAssertTrue(RootOverlayView.isUsableCanvas(CGSize(width: 1920, height: 1080)))
        XCTAssertTrue(RootOverlayView.isUsableCanvas(CGSize(width: 1, height: 1)))
    }

    func testUsableCanvasRejectsDegenerateMeasurements() {
        XCTAssertFalse(RootOverlayView.isUsableCanvas(.zero))
        XCTAssertFalse(RootOverlayView.isUsableCanvas(CGSize(width: 0, height: 1080)))
        XCTAssertFalse(RootOverlayView.isUsableCanvas(CGSize(width: 1920, height: 0)))
        XCTAssertFalse(RootOverlayView.isUsableCanvas(CGSize(width: -1920, height: 1080)))
        XCTAssertFalse(RootOverlayView.isUsableCanvas(CGSize(width: CGFloat.infinity, height: 1080)))
        XCTAssertFalse(RootOverlayView.isUsableCanvas(CGSize(width: 1920, height: CGFloat.nan)))
    }
}
