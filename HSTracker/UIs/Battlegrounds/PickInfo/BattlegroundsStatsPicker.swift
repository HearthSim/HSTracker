//
//  BackgroundsPickers.swift
//  HSTracker
//
//  Created by IHume on 2025-06-20.
//  Copyright © 2025 Benjamin Michotte. All rights reserved.
//

import SwiftUI

@available(macOS 10.15, *)
struct BattlegroundsStatsPicker: View {
    let viewModel: StatsHeaderViewModel
    let itemHasCost: Bool
    
    init(viewModel: StatsHeaderViewModel) {
        self.viewModel = viewModel
        self.itemHasCost = false
    }
    
    init(viewModel: StatsHeaderViewModel, itemHasCost: Bool) {
        self.viewModel = viewModel
        self.itemHasCost = itemHasCost
    }

    var body: some View {
        let placementString = if let placement = viewModel.avgPlacement {
            "\(Double(round(100 * placement) / 100))"
        } else {
            "—"
        }
        let pickRateString = if let pickRate = viewModel.pickRate {
            "\(Double(round(10 * pickRate) / 10))%"
        } else {
            "—"
        }

        return HStack(alignment: .top, spacing: 3, content: {
            PickData(
                title: "Avg Placement",
                value: placementString,
                clipSide: itemHasCost ? .RightIcon : .RightPortrait,
                color: Color(hex: viewModel.avgPlacementColor)
            ).padding([.top], itemHasCost ? 30 : 0)
            StatTier(tier: Tier(rawValue: viewModel.tierChar) ?? Tier.A)
            PickData(
                title: "Pick Rate",
                value: pickRateString,
                clipSide: itemHasCost ? .LeftIcon : .LeftPortrait
            ).padding([.top], itemHasCost ? 30 : 0)
        })
    }
}

@available(macOS 10.15, *)
#Preview {
    return VStack {
        BattlegroundsStatsPicker(
            viewModel:
                StatsHeaderViewModel(
                    tier: "s",
                    avgPlacement: 3.12,
                    pickRate: 26.3
                )
        )
        BattlegroundsStatsPicker(
            viewModel:
                StatsHeaderViewModel(
                    tier: "a",
                    avgPlacement: 3.12,
                    pickRate: 26.3
                ),
            itemHasCost: true
        )
    }
}
