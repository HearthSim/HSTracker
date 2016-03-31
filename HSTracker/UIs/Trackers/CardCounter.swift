//
//  OpponentCount.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 31/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Cocoa

class CardCounter: TrackerFrame {
    
    private let frameRect = NSMakeRect(0, 0, CGFloat(kFrameWidth), 40)
    private let handFrame = NSMakeRect(65, 4, 68, 25)
    private let deckFrame = NSMakeRect(160, 4, 68, 25)
    
    var handCount = 30
    var deckCount = 0
    
    private var imageLayer: CALayer?
    private var handCountLayer: CATextLayer?
    private var deckCountLayer: CATextLayer?

    override func updateLayer() {
        if imageLayer == nil {
            imageLayer = addChild(ImageCache.asset("card-counter-frame"), frameRect)
        }
        if handCountLayer == nil {
            handCountLayer = addText("\(handCount)", handFrame)
        }
        else {
            setText(handCountLayer!, "\(handCount)")
        }
        if deckCountLayer == nil {
            deckCountLayer = addText("\(deckCount)", deckFrame)
        }
        else {
            setText(deckCountLayer!, "\(deckCount)")
        }
    }
}
