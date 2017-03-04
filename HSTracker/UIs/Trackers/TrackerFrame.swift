//
//  TrackerFrame.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 31/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Cocoa
import TextAttributes

class TextFrame: NSView {

    init() {
        super.init(frame: NSRect.zero)
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

        self.layer!.backgroundColor = NSColor.clear.cgColor
    }

    func ratio(_ rect: NSRect) -> NSRect {
        return NSRect(x: rect.origin.x / ratioWidth,
                      y: rect.origin.y / ratioHeight,
                      width: rect.size.width / ratioWidth,
                      height: rect.size.height / ratioHeight)
    }

    var ratioWidth: CGFloat {
        switch Settings.cardSize {
        case .tiny: return CGFloat(kRowHeight / kTinyRowHeight)
        case .small: return CGFloat(kRowHeight / kSmallRowHeight)
        case .medium: return CGFloat(kRowHeight / kMediumRowHeight)
        case .huge: return CGFloat(kRowHeight / kHighRowHeight)
        case .big: return 1.0
        }
    }

    var ratioHeight: CGFloat {
        return ratioWidth
    }

    func add(image filename: String, rect: NSRect) {
        let theme = Settings.theme

        var fullPath = Bundle.main.resourcePath!
            + "/Resources/Themes/Overlay/\(theme)/\(filename)"
        if !FileManager.default.fileExists(atPath: fullPath) {
            fullPath = Bundle.main.resourcePath!
                + "/Resources/Themes/Overlay/default/\(filename)"
        }

        guard let image = NSImage(contentsOfFile: fullPath) else {return}
        image.draw(in: ratio(rect))
    }

    func add(int val: Int, rect: NSRect) {
        add(string: "\(val)", rect: rect)
    }

    func add(double val: Double, rect: NSRect) {
        let format = val == Double(Int(val)) ? "%.0f%%" : "%.2f%%"
        add(string: String(format: format, val), rect: rect)
    }

    func add(string val: String, rect: NSRect, alignment: NSTextAlignment = .left) {
        let attributes = TextAttributes()
            .font(NSFont(name: "ChunkFive", size: round(18 / ratioHeight)))
            .foregroundColor(.white)
            .strokeColor(.black)
            .strokeWidth(-2)
            .alignment(alignment)

        NSAttributedString(string: val, attributes: attributes)
            .draw(in: ratio(rect))
    }
}
