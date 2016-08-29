//
//  ThemeElementInfo.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 31/05/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

struct ThemeElementInfo {
    let filename: String
    let rect: NSRect

    init(filename: String, rect: NSRect) {
        self.filename = filename
        self.rect = rect
    }

    init(filename: String, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        self.filename = filename
        self.rect = NSRect(x: x, y: y, width: width, height: height)
    }
}

enum ThemeElement {
    case DefaultFrame,
    CommonFrame,
    RareFrame,
    EpicFrame,
    LegendaryFrame,
    DefaultGem,
    CommonGem,
    RareGem,
    EpicGem,
    LegendaryGem,
    DefaultCountBox,
    CommonCountBox,
    RareCountBox,
    EpicCountBox,
    LegendaryCountBox,
    LegendaryIcon,
    CreatedIcon,
    DarkOverlay,
    FadeOverlay,
    FlashFrame
}