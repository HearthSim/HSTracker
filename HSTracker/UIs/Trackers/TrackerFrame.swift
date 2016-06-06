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

class TextFrame: NSView {

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

    func addImage(filename: String, rect: NSRect) {
        let theme = Settings.instance.theme

        var fullPath = NSBundle.mainBundle().resourcePath!
            + "/Resources/Themes/Overlay/\(theme)/\(filename)"
        if !NSFileManager.defaultManager().fileExistsAtPath(fullPath) {
            fullPath = NSBundle.mainBundle().resourcePath!
                + "/Resources/Themes/Overlay/default/\(filename)"
        }

        guard let image = NSImage(contentsOfFile: fullPath) else {return}
        image.drawInRect(ratio(rect))
    }

    func addInt(val: Int, rect: NSRect) {
        addString("\(val)", rect: rect)
    }

    func addDouble(val: Double, rect: NSRect) {
        let format = val == Double(Int(val)) ? "%.0f%%" : "%.2f%%"
        addString(String(format: format, val), rect: rect)
    }

    func addString(val: String, rect: NSRect, alignment: NSTextAlignment = .Left) {
        let attributes = TextAttributes()
            .font(NSFont(name: "ChunkFive", size: round(18 / ratioHeight)))
            .foregroundColor(NSColor.whiteColor())
            .strokeColor(NSColor.blackColor())
            .strokeWidth(-2)
            .alignment(alignment)

        NSAttributedString(string: val, attributes: attributes)
            .drawInRect(ratio(rect))
    }
}
