//
//  PlayerDrawChance.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 31/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class PlayerDrawChance: TrackerFrame {
    
    private let frameRect = NSMakeRect(0, 0, CGFloat(kFrameWidth), 40)
    private let draw1Frame = NSMakeRect(78, 4, 68, 25)
    private let draw2Frame = NSMakeRect(155, 4, 68, 25)
    
    var drawChance1 = 0.0
    var drawChance2 = 0.0
    
    override func updateLayer() {
        if let layer = self.layer, sublayers = layer.sublayers {
            for sublayer in sublayers {
                sublayer.removeFromSuperlayer()
            }
        }
            
        addChild(ImageCache.asset("player-chance-frame"), frameRect)
        addText(String(format: "%.2f%%", drawChance1), draw1Frame)
        addText(String(format: "%.2f%%", drawChance2), draw2Frame)
    }
}
