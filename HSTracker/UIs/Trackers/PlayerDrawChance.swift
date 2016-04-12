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
    
    private var imageLayer: CALayer?
    private var drawChance1Layer: CATextLayer?
    private var drawChance2Layer: CATextLayer?
    
    override func updateLayer() {
        if imageLayer == nil {
            imageLayer = addChild(ImageCache.asset("player-chance-frame"), frameRect)
        }
        
        if drawChance1Layer == nil {
            drawChance1Layer = addText(String(format: "%.2f%%", drawChance1), draw1Frame)
        }
        else {
            setText(drawChance1Layer!, String(format: "%.2f%%", drawChance1))
        }
        
        if drawChance2Layer == nil {
            drawChance2Layer = addText(String(format: "%.2f%%", drawChance2), draw2Frame)
        }
        else {
            setText(drawChance2Layer!, String(format: "%.2f%%", drawChance2))
        }
    }
}
