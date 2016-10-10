//
//  CardHud.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 12/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger
import TextAttributes

class CardHud: NSView {
    var entity: Entity?
    var card: Card?
    
    private lazy var trackingArea: NSTrackingArea = {
        return NSTrackingArea(rect: NSRect.zero,
                              options: [.InVisibleRect, .ActiveAlways, .MouseEnteredAndExited],
                              owner: self,
                              userInfo: nil)
    }()
    
    private let cardMarkerFrame = NSRect(x: 1, y: 7, width: 32, height: 32)
    private let iconFrame = NSRect(x: 20, y: 3, width: 16, height: 16)
    private let costReductionFrame = NSRect(x: 0, y: 25, width: 37, height: 26)
    private let turnFrame = NSRect(x: 1, y: 13, width: 33, height: 31)
    
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
        self.layer!.backgroundColor = NSColor.clearColor().CGColor
    }
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        
        addImage("card-marker", rect: cardMarkerFrame)
        
        var text = ""
        var image: String? = nil
        var cost = 0
        card = nil
        
        if let entity = entity {
            text = "\(entity.info.turn)"
            
            switch entity.info.cardMark {
            case .Coin: image = "coin"
            case .Kept: image = "kept"
            case .Mulliganed: image = "mulliganed"
            case .Returned: image = "returned"
            case .Created: image = "created"
            default: break
            }
            cost = entity.info.costReduction
            
            if entity.info.cardMark == .Coin {
                card = Cards.any(byId: CardIds.NonCollectible.Neutral.TheCoin)
            } else if !String.isNullOrEmpty(entity.cardId) && !entity.info.hidden {
                image = "small-card"
                card = Cards.by(cardId: entity.cardId)
            }
        }
        if let image = image {
            addImage(image, rect: iconFrame)
        }
        
        let attributes = TextAttributes()
            .font(NSFont(name: "Belwe Bd BT", size: 20))
            .foregroundColor(NSColor.whiteColor())
            .strokeWidth(-2)
            .strokeColor(NSColor.blackColor())
            .alignment(.Center)
        NSAttributedString(string: text, attributes: attributes)
            .drawInRect(turnFrame)
        
        if cost > 0 {
            let costReductionAttributes = TextAttributes()
                .font(NSFont(name: "Belwe Bd BT", size: 16))
                .foregroundColor(NSColor(red: 0.117, green: 0.56, blue: 1, alpha: 1))
                .strokeWidth(-2)
                .strokeColor(NSColor.blackColor())
            NSAttributedString(string: "-\(cost)", attributes: costReductionAttributes)
                .drawInRect(costReductionFrame)
        }
    }
    
    private func addImage(filename: String, rect: NSRect) {
        guard let image = NSImage(named: filename) else { return }
        image.drawInRect(rect)
    }

    // MARK: - mouse hover
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        if !self.trackingAreas.contains(trackingArea) {
            self.addTrackingArea(trackingArea)
        }
    }

    override func mouseEntered(event: NSEvent) {
        guard let card = self.card else { return }
        guard let rect = self.superview?.convertRect(self.frame, toView: nil) else { return }
        guard let frame = self.superview?.window?.convertRectToScreen(rect) else { return }

        var screenRect = frame
        screenRect.origin.x += rect.width - 30
        screenRect.origin.y -= 250
        screenRect.size = NSSize(width: 200, height: 300)
        
        NSNotificationCenter.defaultCenter()
            .postNotificationName("show_floating_card",
                                  object: nil,
                                  userInfo: [
                                    "card": card,
                                    "frame": [
                                        screenRect.origin.x + rect.width - 30,
                                        screenRect.origin.y,
                                        200,
                                        300
                                    ]
                ])
    }

    override func mouseExited(event: NSEvent) {
        guard let _ = card else { return }
 
        NSNotificationCenter.defaultCenter()
            .postNotificationName("hide_floating_card", object: nil)
    }
}
