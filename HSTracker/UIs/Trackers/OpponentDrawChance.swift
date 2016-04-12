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
    
    private var imageLayer: CALayer?
    private var drawChance1Layer: CATextLayer?
    private var drawChance2Layer: CATextLayer?
    private var handChance1Layer: CATextLayer?
    private var handChance2Layer: CATextLayer?
    
    override func updateLayer() {
        if imageLayer == nil {
            imageLayer = addChild(ImageCache.asset("opponent-chance-frame"), frameRect)
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
        
        if handChance1Layer == nil {
            handChance1Layer = addText(String(format: "%.2f%%", handChance1), hand1Frame)
        }
        else {
            setText(handChance1Layer!, String(format: "%.2f%%", handChance1))
        }
        
        if handChance2Layer == nil {
            handChance2Layer = addText(String(format: "%.2f%%", handChance2), hand2Frame)
        }
        else {
            setText(handChance2Layer!, String(format: "%.2f%%", handChance2))
        }
    }

}