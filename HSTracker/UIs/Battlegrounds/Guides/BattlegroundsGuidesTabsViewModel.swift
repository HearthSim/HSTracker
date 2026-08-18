//
//  BattlegroundsGuidesTabsViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 8/13/26.
//  Copyright © 2026 Benjamin Michotte. All rights reserved.
//

import Foundation

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
    @Published var activeTab: GuidesTab?

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
