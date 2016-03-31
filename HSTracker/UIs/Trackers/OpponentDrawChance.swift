//
//  CountTextCellView.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 6/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Cocoa

class OpponentDrawChance: TrackerFrame {
    
    private let frameRect = NSMakeRect(0, 0, CGFloat(kFrameWidth), 71)
    private let draw1Frame = NSMakeRect(74, 36, 68, 25)
    private let draw2Frame = NSMakeRect(154, 36, 68, 25)
    private let hand1Frame = NSMakeRect(74, 4, 68, 25)
    private let hand2Frame = NSMakeRect(154, 4, 68, 25)

    var drawChance1 = 0.0
    var drawChance2 = 0.0
    var handChance1 = 0.0
    var handChance2 = 0.0
    
    override func updateLayer() {
        if let layer = self.layer, sublayers = layer.sublayers {
            for sublayer in sublayers {
                sublayer.removeFromSuperlayer()
            }
        }
            
        addChild(ImageCache.asset("opponent-chance-frame"), frameRect)
        addText(String(format: "%.2f%%", drawChance1), draw1Frame)
        addText(String(format: "%.2f%%", drawChance2), draw2Frame)
        addText(String(format: "%.2f%%", handChance1), hand1Frame)
        addText(String(format: "%.2f%%", handChance2), hand2Frame)
    }

}