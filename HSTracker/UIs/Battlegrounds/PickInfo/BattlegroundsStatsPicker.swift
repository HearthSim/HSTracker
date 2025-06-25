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
// Extend SwiftUI color to be able to accept hex string that avgPlacementColor is generating
// from the placement value. Implementation from: https://blog.eidinger.info/from-hex-to-color-and-back-in-swiftui
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0

        let length = hexSanitized.count

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0

        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0

        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b, opacity: a)
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
