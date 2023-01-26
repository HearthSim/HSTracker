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
    private(set) var avgPlacement: Double?
    private(set) var pickRate: Double?
    
    init(tier: Int?, avgPlacement: Double?, pickRate: Double?) {
        super.init()
        
        self.tier = tier
        self.avgPlacement = avgPlacement
        self.pickRate = pickRate
    }
    
    var tierGradient: CALayer {
        let result = CAGradientLayer()
        result.cornerRadius = 4.0
        switch tier {
        case 1:
            result.colors = [ NSColor.fromHexString(hex: "#06a9d36")!.cgColor, NSColor.fromHexString(hex: "#587937")!.cgColor ]
        case 2:
            result.colors = [ NSColor.fromHexString(hex: "#092a036")!.cgColor, NSColor.fromHexString(hex: "#687937")!.cgColor ]
        case 3:
            result.colors = [ NSColor.fromHexString(hex: "#a07c36")!.cgColor, NSColor.fromHexString(hex: "#795f37")!.cgColor ]
        case 4:
            result.colors = [ NSColor.fromHexString(hex: "#a03636")!.cgColor, NSColor.fromHexString(hex: "#793737")!.cgColor ]
        default:
            let layer = CALayer()
            layer.backgroundColor = NSColor.fromHexString(hex: "#141617")!.cgColor
            layer.cornerRadius = 4.0
            return layer
        }
        return result
    }
    
    var avgPlacementColor: String {
        switch tier {
        case 1:
            return "#6BA036"
        case 2:
            return "#92A036"
        case 3:
            return "#A07C36"
        case 4:
            return "#B44646"
        default:
            return "#FFFFFF"
        }
    }
}
