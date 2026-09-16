//
//  BattlegroundsHeroHeaderViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/18/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

// Port of HDT's BattlegroundsHeroHeaderViewModel
// (Controls/Overlay/Battlegrounds/HeroPicking/BattlegroundsHeroHeaderViewModel.cs).
//
// StatsHeaderViewModel, the base it shares with the still-AppKit quest and
// trinket pickers, stays on the old ViewModel; only this subclass - whose one
// mutable property drives a SwiftUI view - is an ObservableObject, which is
// also why it carries the 10.15 gate the base does not.
@available(macOS 10.15, *)
class BattlegroundsHeroHeaderViewModel: StatsHeaderViewModel, ObservableObject {

    let placementDistribution: [Double]?
    let onPlacementHover: ((_ isVisible: Bool) -> Void)?

    init(tier: String?, avgPlacement: Double?, pickRate: Double?, placementDistribution: [Double], onPlacementHover: @escaping ((_ isVisible: Bool) -> Void)) {
        self.placementDistribution = placementDistribution
        self.onPlacementHover = onPlacementHover
        super.init(tier: tier, avgPlacement: avgPlacement, pickRate: pickRate)
    }

    @Published var placementDistributionVisibility = false
}
