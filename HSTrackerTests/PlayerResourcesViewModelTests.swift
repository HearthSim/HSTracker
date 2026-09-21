//
//  PlayerResourcesViewModelTests.swift
//  HSTracker
//
//  Created by Francisco Moraes on 9/21/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import XCTest
@testable import HSTracker

// Ports HDT's PlayerResourcesViewModelTests.
class PlayerResourcesViewModelTests: HSTrackerTests {
    private static let goldIcon = "coin-cost"
    private static let manaIcon = "mana"

    private func makeViewModel() -> PlayerResourcesViewModel {
        let viewModel = PlayerResourcesViewModel(isPlayer: true)
        viewModel.initialize(30, 10, 10)
        return viewModel
    }

    func testMaxGoldNotShownWhenNotProvided() {
        let viewModel = makeViewModel()

        viewModel.updatePlayerResourcesWidget(30, 10, 10)

        XCTAssertFalse(viewModel.hasVisibleResources)
    }

    func testMaxGoldShownWhenProvided() {
        let viewModel = makeViewModel()

        viewModel.updatePlayerResourcesWidget(30, 10, 10, nil, 12)

        XCTAssertEqual(viewModel.resources.count, 1)
        XCTAssertEqual(viewModel.resources.first?.icon, Self.goldIcon)
        XCTAssertEqual(viewModel.resources.first?.value, 12)
    }

    func testMaxGoldDisappearsWhenNoLongerProvided() {
        let viewModel = makeViewModel()

        viewModel.updatePlayerResourcesWidget(30, 10, 10, nil, 12)
        viewModel.updatePlayerResourcesWidget(30, 10, 10)

        XCTAssertFalse(viewModel.hasVisibleResources)
    }

    func testMaxManaStaysVisibleAfterDeviatingFromInitial() {
        let viewModel = makeViewModel()

        viewModel.updatePlayerResourcesWidget(30, 12, 10)
        viewModel.updatePlayerResourcesWidget(30, 10, 10)

        XCTAssertEqual(viewModel.resources.count, 1)
        XCTAssertEqual(viewModel.resources.first?.icon, Self.manaIcon)
        XCTAssertEqual(viewModel.resources.first?.value, 10)
    }

    func testInitializeClearsMaxGoldFromPreviousGame() {
        let viewModel = makeViewModel()
        viewModel.updatePlayerResourcesWidget(30, 10, 10, nil, 12)

        viewModel.initialize(30, 10, 10)

        XCTAssertFalse(viewModel.hasVisibleResources)
    }

    func testInitializeClearsConstructedResourcesFromPreviousGame() {
        let viewModel = makeViewModel()
        viewModel.updatePlayerResourcesWidget(40, 12, 12, 3)

        viewModel.initialize(30, 10, 10)

        XCTAssertFalse(viewModel.hasVisibleResources)
    }
}
