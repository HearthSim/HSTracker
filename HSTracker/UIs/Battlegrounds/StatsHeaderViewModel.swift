//
//  StatsHeaderViewModel.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/11/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class StatsHeaderViewModel: ViewModel {
    private(set) var tier: Int?
    private(set) var tierV2: String?
    private(set) var avgPlacement: Double?
    private(set) var pickRate: Double?
    
    init(tier: Int?, avgPlacement: Double?, pickRate: Double?) {
        super.init()
        
        self.tier = tier
        self.avgPlacement = avgPlacement
        self.pickRate = pickRate
    }
    
    init(tier: String?, avgPlacement: Double?, pickRate: Double?) {
        super.init()
        
        self.tierV2 = tier
        self.avgPlacement = avgPlacement
        self.pickRate = pickRate
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
    
    var tierGradient: CALayer {
        let result = CAGradientLayer()
        result.cornerRadius = 4.0
        if let tierV2 {
            switch tierV2 {
            case "s":
                result.colors = [ NSColor.fromRgb(0x40, 0x8a, 0xbf).cgColor, NSColor.fromRgb(0x38, 0x5F, 0x7a).cgColor ]
            case "a":
                result.colors = [ NSColor.fromRgb(0x6A, 0x9D, 0x36).cgColor, NSColor.fromRgb(0x58, 0x79, 0x37).cgColor ]
            case "b":
                result.colors = [ NSColor.fromRgb(0x92, 0xA0, 0x36).cgColor, NSColor.fromRgb(0x68, 0x79, 0x37).cgColor ]
            case "c":
                result.colors = [ NSColor.fromRgb(0xA0, 0x7C, 0x36).cgColor, NSColor.fromRgb(0x79, 0x5F, 0x37).cgColor ]
            case "d":
                result.colors = [ NSColor.fromRgb(0xA0, 0x48, 0x36).cgColor, NSColor.fromRgb(0x79, 0x42, 0x37).cgColor ]
            case "f":
                result.colors = [ NSColor.fromRgb(0xA0, 0x36, 0x36).cgColor, NSColor.fromRgb(0x79, 0x37, 0x37).cgColor ]
            default:
                let layer = CALayer()
                layer.backgroundColor = NSColor.fromRgb(0x14, 0x16, 0x17).cgColor
                layer.cornerRadius = 4.0
                return layer
            }
        } else {
            switch tier {
            case 1:
                result.colors = [ NSColor.fromRgb(0x6a, 0x9d, 0x36).cgColor, NSColor.fromRgb(0x58, 0x79, 0x37).cgColor ]
            case 2:
                result.colors = [ NSColor.fromRgb(0x92, 0xa0, 0x36).cgColor, NSColor.fromRgb(0x68, 0x79, 0x37).cgColor ]
            case 3:
                result.colors = [ NSColor.fromRgb(0xa0, 0x7c, 0x36).cgColor, NSColor.fromRgb(0x79, 0x5f, 0x37).cgColor ]
            case 4:
                result.colors = [ NSColor.fromRgb(0xa0, 0x36, 0x36).cgColor, NSColor.fromRgb(0x79, 0x37, 0x37).cgColor ]
            default:
                let layer = CALayer()
                layer.backgroundColor = NSColor.fromRgb(0x14, 0x16, 0x17).cgColor
                layer.cornerRadius = 4.0
                return layer
            }
        }
        return result
    }
    
    var avgPlacementColor: String {
        if let avgPlacement {
            return Helper.getColorString(mode: .BATTLEGROUNDS, delta: (4.5 - avgPlacement) * 100.0 / 3.5, intensity: 75)
        }
        return "#FFFFFF"
    }
}
