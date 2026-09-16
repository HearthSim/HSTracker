//
//  ConstructedStatsHeaderViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 2/16/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import SwiftUI

// HDT's StatsHeaderViewModel, the values behind one card's stats header in the
// V1 mulligan guide.
@available(macOS 10.15, *)
class ConstructedStatsHeaderViewModel: ObservableObject {
    private(set) var rank: Int?
    private(set) var mulliganWr: Double?
    private(set) var keepRate: Double?
    private(set) var maxRank: Int?
    private(set) var baseWinRate: Double?

    init(rank: Int?, mulliganWr: Double?, keepRate: Double?, maxRank: Int?, baseWinRate: Double?) {
        self.rank = rank
        self.mulliganWr = mulliganWr
        self.keepRate = keepRate
        self.maxRank = maxRank
        self.baseWinRate = baseWinRate
    }

    // StatsHeaderViewModel.RankGradient. HDT builds a LinearGradientBrush with
    // an angle of 0, which is a plain left-to-right ramp, and a flat #141617
    // when there is no rank to show - returned here as a two-stop pair either
    // way so the view has one thing to draw.
    var rankGradient: [Color] {
        guard let rank, let maxRank else {
            return [Color(hex: "#141617"), Color(hex: "#141617")]
        }
        if Double(rank) <= Double(maxRank) * 0.25 {
            // 0x6A9D36 -> 0x587937. The old AppKit port had this first stop as
            // "#06a9d36", a seven-digit string the hex parser could not read.
            return [Color(hex: "#6a9d36"), Color(hex: "#587937")]
        }
        if Double(rank) <= Double(maxRank) * 0.5 {
            return [Color(hex: "#92a036"), Color(hex: "#687937")]
        }
        if Double(rank) <= Double(maxRank) * 0.75 {
            return [Color(hex: "#a07c36"), Color(hex: "#795f37")]
        }
        return [Color(hex: "#a03636"), Color(hex: "#793737")]
    }

    var mulliganWrColor: Color {
        if let mulliganWr {
            return Color(hex: Helper.getColorString(delta: mulliganWr - (baseWinRate ?? 50.0), intensity: 75))
        }
        return .white
    }

    var handRankTooltipText: String {
        String(format: String.localizedString("ConstructedMulliganGuide_Header_HandRankTooltip_Desc", comment: ""), rank ?? 0, maxRank ?? 0)
    }
}
