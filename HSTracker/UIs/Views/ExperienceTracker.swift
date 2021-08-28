//
//  ExperienceTracker.swift
//  HSTracker
//
//  Created by Francisco Moraes on 1/9/21.
//  Copyright © 2021 Benjamin Michotte. All rights reserved.
//

import Foundation

class ExperienceTracker: NSView {

    var levelDisplay: String = ""
    var xpDisplay: String = ""
    var xpPercentage: Double = 0.0
    
    static let xpBarRect = NSRect(x: 70, y: 30, width: 356, height: 65)
    static let gemRect = NSRect(x: 410, y: 24, width: 111, height: 78)
    static let scrollRect = NSRect(x: 0, y: 0, width: 121, height: 126)
    
    init() {
        super.init(frame: NSRect.zero)
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let backgroundColor: NSColor = NSColor.clear
        
        backgroundColor.set()
        dirtyRect.fill()
        
        let image = NSImage.init(size: NSSize(width: 521, height: 126))

        image.lockFocus()
        
        if let emptyBarImage = NSImage(named: "xp_empty_bar") {
            emptyBarImage.draw(in: ExperienceTracker.xpBarRect)
        }
        
        if let fullBarImage = NSImage(named: "xp_filled_bar") {
            NSGraphicsContext.saveGraphicsState()

            let w = 356.0 * xpPercentage
            let rect = NSRect(x: ExperienceTracker.xpBarRect.minX, y: ExperienceTracker.xpBarRect.minY, width: CGFloat(w), height: ExperienceTracker.xpBarRect.height)
            let path = NSBezierPath(rect: rect)
            path.setClip()

            fullBarImage.draw(in: ExperienceTracker.xpBarRect)
            
            NSGraphicsContext.restoreGraphicsState()
        }
        
        drawText(text: xpDisplay, rect: ExperienceTracker.xpBarRect, color: .white)
        
        if let gemImage = NSImage(named: "xp_gem") {
            gemImage.draw(in: ExperienceTracker.gemRect)
        }
        
        drawText(text: levelDisplay, rect: ExperienceTracker.gemRect, color: .white)
        
        if let scrollImage = NSImage(named: "xp_scroll_item") {
            scrollImage.draw(in: ExperienceTracker.scrollRect)
        }
        
        image.unlockFocus()

        image.draw(in: visibleRect)
    }
    
    func drawText(text: String, rect: NSRect, color: NSColor) {
        if let font = NSFont(name: "ChunkFive", size: 30) {
            var attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color,
                .strokeWidth: -2,
                .strokeColor: NSColor.black
            ]
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            attributes[.paragraphStyle] = paragraph
            
            let size = text.size(withAttributes: attributes)

            let finalRect = NSRect(x: rect.origin.x, y: font.leading + rect.origin.y + (rect.height - size.height) / 2, width: rect.width, height: rect.height)
            
            text.draw(with: finalRect, options: NSString.DrawingOptions.truncatesLastVisibleLine,
                                        attributes: attributes)
        }
    }
}
