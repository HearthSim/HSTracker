//
//  BattlegroundsGuidesTabsViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation
import Combine

// Mirrors HDT's BattlegroundsGuidesTabsViewModel.ActiveViewModel - which of
// GuidesTabsView's tabs is currently expanded, or none. Trinkets/Anomalies
// never get a case here - HDT never gives them a tab either, they're
// tooltip-only.
@available(macOS 10.15, *)
enum GuidesTab: Equatable {
    case comps
    case heroes
    case minions
}

@available(macOS 10.15, *)
final class BattlegroundsGuidesTabsViewModel: ObservableObject {
    // Mirrors HDT's UpdateBgsTopBarContentVisibility: the browser flag gates the
    // whole top bar apart from the turn counter, the guides flag picks whether
    // the browser appears inside the tabs or on its own (its "stand alone" mode).
    //
    // Snapshotted rather than read from Settings at render time so SwiftUI has a
    // dependency to invalidate on when either checkbox is toggled mid-match.
    @Published private(set) var showBrowser = Settings.showBattlegroundsBrowser
    @Published private(set) var showGuides = Settings.showBattlegroundsGuides

    /// True when the browser shows without the tabs above it - HDT's IsStandAloneMode.
    var isStandAlone: Bool { !showGuides }

    private var settingsCancellable: AnyCancellable?

    init() {
        settingsCancellable = NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refreshVisibility() }
    }

    private func refreshVisibility() {
        if showBrowser != Settings.showBattlegroundsBrowser {
            showBrowser = Settings.showBattlegroundsBrowser
        }
        if showGuides != Settings.showBattlegroundsGuides {
            showGuides = Settings.showBattlegroundsGuides
        }
    }

    @Published var activeTab: GuidesTab? {
        didSet {
            // HDT closes the minions extra-filters panel on every tab change
            // (BattlegroundsGuidesTabsViewModel: `IsFiltersOpen = false`). It
            // hangs off the left of the Minions tab, so leaving it open while
            // another tab - or none - is showing would strand it mid-air.
            if oldValue != activeTab {
                AppDelegate.instance().coreManager?.game.windowManager
                    .rootOverlay?.viewModel.battlegroundsMinionsGuide.isFiltersOpen = false
            }
        }
    }

    // Matches HDT's ShowCompsCommand/ShowHeroesCommand/ShowMinionsCommand:
    // clicking the already-active tab's icon collapses it rather than doing nothing.
    func toggleComps() {
        activeTab = activeTab == .comps ? nil : .comps
    }

    func toggleHeroes() {
        activeTab = activeTab == .heroes ? nil : .heroes
    }

    func toggleMinions() {
        activeTab = activeTab == .minions ? nil : .minions
    }
}
