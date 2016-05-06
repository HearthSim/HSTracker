//
//  TrackerFrame.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 31/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Cocoa
import TextAttributes

let kFrameWidth = 217.0
let kFrameHeight = 700.0
let kRowHeight = 34.0

let kMediumRowHeight = 29.0
let kMediumFrameWidth = (kFrameWidth / kRowHeight * kMediumRowHeight)

let kSmallRowHeight = 23.0
let kSmallFrameWidth = (kFrameWidth / kRowHeight * kSmallRowHeight)

enum CardSize: Int {
    case Small,
    Medium,
    Big
}

class TrackerFrame: NSView {

    var playerType: PlayerType?

    init() {
        super.init(frame: NSZeroRect)
        initLayers()
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        initLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initLayers()
    }

    func initLayers() {
        self.wantsLayer = true

        self.layer!.backgroundColor = NSColor.clearColor().CGColor
    }

    func ratio(rect: NSRect) -> NSRect {
        return NSRect(x: rect.origin.x / ratioWidth,
                      y: rect.origin.y / ratioHeight,
                      width: rect.size.width / ratioWidth,
                      height: rect.size.height / ratioHeight)
    }

    var ratioWidth: CGFloat {
        if let playerType = playerType where playerType == .DeckManager {
            return 1.0
        }

        var ratio: CGFloat
        switch Settings.instance.cardSize {
        case .Small: ratio = CGFloat(kRowHeight / kSmallRowHeight)
        case .Medium: ratio = CGFloat(kRowHeight / kMediumRowHeight)
        default: ratio = 1.0
        }
        return ratio
    }

    var ratioHeight: CGFloat {
        return ratioWidth
    }

    func addImage(image: NSImage?, _ rect: NSRect) {
        guard let image = image else {return}

        let resizedRect = ratio(rect)
        image.drawInRect(resizedRect)
    }
}

class TextFrame: TrackerFrame {
    func addInt(val: Int, _ rect: NSRect) {
        addString("\(val)", rect)
    }

    func addDouble(val: Double, _ rect: NSRect) {
        let format = val == Double(Int(val)) ? "%.0f%%" : "%.2f%%"
        addString(String(format: format, val), rect)
    }

    func addString(val: String, _ rect: NSRect) {
        let attributes = TextAttributes()
            .font(NSFont(name: "Belwe Bd BT", size: round(18 / ratioHeight)))
            .foregroundColor(NSColor.whiteColor())
            .strokeColor(NSColor.blackColor())
            .strokeWidth(-2)


        NSAttributedString(string: val, attributes: attributes)
            .drawInRect(ratio(rect))
    }
}
