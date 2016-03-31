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

    override func updateLayer() {
        if let layer = self.layer, sublayers = layer.sublayers {
            for sublayer in sublayers {
                sublayer.removeFromSuperlayer()
            }
        }
        
        addChild(ImageCache.asset("card-counter-frame"), frameRect)
        addText("\(handCount)", handFrame)
        addText("\(deckCount)", deckFrame)
    }
}
