//
//  StatsHeaderViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 2/16/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class ConstructedStatsHeaderViewModel: ViewModel {
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
    
    var rankGradient: CALayer {
        let result = CAGradientLayer()
        result.cornerRadius = 4.0

        guard let rank, let maxRank else {
            let layer = CALayer()
            layer.backgroundColor = NSColor.fromHexString(hex: "#141617")!.cgColor
            layer.cornerRadius = 4.0
            return layer
        }
        if rank <= Int(Double(maxRank) * 0.25) {
            result.colors = [ NSColor.fromHexString(hex: "#06a9d36")!.cgColor, NSColor.fromHexString(hex: "#587937")!.cgColor ]
            return result
        }
        if rank <= Int(Double(maxRank) * 0.5) {
            result.colors = [ NSColor.fromHexString(hex: "#92a036")!.cgColor, NSColor.fromHexString(hex: "#687937")!.cgColor ]
            return result
        }
        if rank <= Int(Double(maxRank) * 0.75) {
            result.colors = [ NSColor.fromHexString(hex: "#a07c36")!.cgColor, NSColor.fromHexString(hex: "#795f37")!.cgColor ]
            return result
        }
        result.colors = [ NSColor.fromHexString(hex: "#a03636")!.cgColor, NSColor.fromHexString(hex: "#793737")!.cgColor ]
        return result
    }
    
    var mulliganWrColor: String {
        if let mulliganWr {
            return Helper.getColorString(delta: mulliganWr - (baseWinRate  ?? 50.0), intensity: 75)
        }
        return "#ffffff"
    }
    
    var handRankTooltipText: String {
        return String(format: String.localizedString("ConstructedMulliganGuide_Header_HandRankTooltip_Desc", comment: ""), rank ?? 0, maxRank ?? 0)
    }
}
