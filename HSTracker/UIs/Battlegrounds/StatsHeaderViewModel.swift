//
//  StatsHeaderViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/11/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation
import SwiftUI

class StatsHeaderViewModel: ViewModel {
    private(set) var tier: Int?
    private(set) var tierV2: String?
    private(set) var avgPlacement: Double?
    private(set) var pickRate: Double?
    // The card this stats header is for, when known - e.g. a trinket's dbfId,
    // used to look up its guide for the hover tooltip.
    private(set) var dbfId: Int?

    init(tier: Int?, avgPlacement: Double?, pickRate: Double?, dbfId: Int? = nil) {
        super.init()

        self.tier = tier
        self.avgPlacement = avgPlacement
        self.pickRate = pickRate
        self.dbfId = dbfId
    }

    init(tier: String?, avgPlacement: Double?, pickRate: Double?, dbfId: Int? = nil) {
        super.init()

        self.tierV2 = tier
        self.avgPlacement = avgPlacement
        self.pickRate = pickRate
        self.dbfId = dbfId
    }

    var tierChar: String {
        if let tierV2 {
            return tierV2.uppercased()
        }
        if let tier {
            return String(tier)
        }
        return "—"
    }
    
    // HDT's TierGradient (StatsHeaderViewModel.cs): a two-stop
    // LinearGradientBrush per tier, or flat Tier7Black when the tier is
    // unknown - expressed as its two stops so both the AppKit layer below and
    // the SwiftUI gradient in the extension at the end of this file can be
    // built from the one table.
    var tierGradientStops: (NSColor, NSColor)? {
        if let tierV2 {
            switch tierV2 {
            case "s":
                return (NSColor.fromRgb(0x40, 0x8a, 0xbf), NSColor.fromRgb(0x38, 0x5F, 0x7a))
            case "a":
                return (NSColor.fromRgb(0x6A, 0x9D, 0x36), NSColor.fromRgb(0x58, 0x79, 0x37))
            case "b":
                return (NSColor.fromRgb(0x92, 0xA0, 0x36), NSColor.fromRgb(0x68, 0x79, 0x37))
            case "c":
                return (NSColor.fromRgb(0xA0, 0x7C, 0x36), NSColor.fromRgb(0x79, 0x5F, 0x37))
            case "d":
                return (NSColor.fromRgb(0xA0, 0x48, 0x36), NSColor.fromRgb(0x79, 0x42, 0x37))
            case "f":
                return (NSColor.fromRgb(0xA0, 0x36, 0x36), NSColor.fromRgb(0x79, 0x37, 0x37))
            default:
                return nil
            }
        }
        switch tier {
        case 1:
            return (NSColor.fromRgb(0x6a, 0x9d, 0x36), NSColor.fromRgb(0x58, 0x79, 0x37))
        case 2:
            return (NSColor.fromRgb(0x92, 0xa0, 0x36), NSColor.fromRgb(0x68, 0x79, 0x37))
        case 3:
            return (NSColor.fromRgb(0xa0, 0x7c, 0x36), NSColor.fromRgb(0x79, 0x5f, 0x37))
        case 4:
            return (NSColor.fromRgb(0xa0, 0x36, 0x36), NSColor.fromRgb(0x79, 0x37, 0x37))
        default:
            return nil
        }
    }

    var tierGradient: CALayer {
        guard let stops = tierGradientStops else {
            let layer = CALayer()
            layer.backgroundColor = NSColor.fromRgb(0x14, 0x16, 0x17).cgColor
            layer.cornerRadius = 4.0
            return layer
        }
        let result = CAGradientLayer()
        result.cornerRadius = 4.0
        result.colors = [ stops.0.cgColor, stops.1.cgColor ]
        return result
    }
    
    var avgPlacementColor: String {
        let game = AppDelegate.instance().coreManager.game
        let pivot = game.isBattlegroundsDuosMatch() ? 2.5 : 4.5
        let factor = game.isBattlegroundsDuosMatch() ? 0.5 : 1.0
        if let avgPlacement {
            return Helper.getColorString(mode: .BATTLEGROUNDS, delta: (pivot - avgPlacement) * 100.0 / 3.5 * factor, intensity: 75)
        }
        return "#FFFFFF"
    }
}

@available(macOS 10.15, *)
extension StatsHeaderViewModel {
    // The same brush as tierGradient above, for SwiftUI. HDT builds it with
    // LinearGradientBrush(start, end, 0) - an angle of 0 degrees, so it runs
    // left to right, not top to bottom the way the CALayer above defaults to.
    var tierLinearGradient: LinearGradient {
        let stops = tierGradientStops ?? (NSColor.fromRgb(0x14, 0x16, 0x17), NSColor.fromRgb(0x14, 0x16, 0x17))
        return LinearGradient(gradient: Gradient(colors: [Color(stops.0), Color(stops.1)]),
                              startPoint: .leading, endPoint: .trailing)
    }
}
