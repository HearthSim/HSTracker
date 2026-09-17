//
//  GraveyardCounter.swift
//  HSTracker
//
//  Created by Istvan Fehervari on 25/09/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import AppKit

/// The graveyard row of a deck tracker: the theme's frame, the number of minions
/// that have died and how many of them were murlocs.
///
/// It used to put up a `CardList` window of its own from a tracking area while
/// the cursor was on it. That list is now `TrackerGraveyardDetailsView`, a
/// sibling of the tracker on the overlay canvas, so nothing is left here but the
/// drawing.
class GraveyardCounter: TextFrame {

    private let frameRect = NSRect(x: 0, y: 0, width: CGFloat(kFrameWidth), height: 40)
    private let firstNumberFrame = NSRect(x: 60, y: 1, width: 68, height: 25)
    private let secondNumberFrame = NSRect(x: 158, y: 1, width: 68, height: 25)

    var minions: Int = 0
    var murlocks: Int = 0

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        add(image: "graveyard-frame.png", rect: frameRect)
        add(int: minions, rect: firstNumberFrame)
        add(int: murlocks, rect: secondNumberFrame)
    }
}
