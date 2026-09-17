//
//  CardSize.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 15/10/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

let kFrameWidth = 217.0
let kFrameHeight = 700.0
let kRowHeight = 34.0

let kHighRowHeight = 52.0
let kHighRowFrameWidth = (kFrameWidth / kRowHeight * kHighRowHeight)

let kMediumRowHeight = 29.0
let kMediumFrameWidth = (kFrameWidth / kRowHeight * kMediumRowHeight)

let kSmallRowHeight = 23.0
let kSmallFrameWidth = (kFrameWidth / kRowHeight * kSmallRowHeight)

let kTinyRowHeight = 17.0
let kTinyFrameWidth = (kFrameWidth / kRowHeight * kTinyRowHeight)

enum CardSize: Int {
    case tiny = -1,
    small = 0,
    medium = 1,
    big = 2,
    huge = 3
}

extension CardSize {
    /// The height one card row is drawn at.
    var rowHeight: Double {
        switch self {
        case .tiny: return kTinyRowHeight
        case .small: return kSmallRowHeight
        case .medium: return kMediumRowHeight
        case .big: return kRowHeight
        case .huge: return kHighRowHeight
        }
    }

    /// The width a tracker is drawn at, which keeps the 217x34 aspect of the
    /// authored row.
    var frameWidth: Double {
        switch self {
        case .tiny: return kTinyFrameWidth
        case .small: return kSmallFrameWidth
        case .medium: return kMediumFrameWidth
        case .big: return kFrameWidth
        case .huge: return kHighRowFrameWidth
        }
    }

    /// What every rect authored against the 217x34 row is divided by to reach this
    /// size - see `TextFrame.ratio`.
    var ratio: Double { kRowHeight / rowHeight }
}
