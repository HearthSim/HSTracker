//
//  CardHud.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 12/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import TextAttributes

class CardHud: NSView {
    var cardAge: Int?
    var costReduction: Int?
    var cardMark: CardMark = .none
    var icon: String?
    var sourceCardImage: NSImage?
    var sourceCard: Card?
    
    private lazy var trackingArea: NSTrackingArea = {
        return NSTrackingArea(rect: NSRect.zero,
                              options: [NSTrackingArea.Options.inVisibleRect, NSTrackingArea.Options.activeAlways, NSTrackingArea.Options.mouseEnteredAndExited],
                              owner: self,
                              userInfo: nil)
    }()
    
    private let cardMarkerFrame = NSRect(x: 1, y: 12, width: 32, height: 32)
    private let iconFrame = NSRect(x: 20, y: 3, width: 16, height: 16)
    private let costReductionFrame = NSRect(x: 0, y: 30, width: 37, height: 26)
    private let turnFrame = NSRect(x: 1, y: 16, width: 33, height: 27)
    private let sourceCardFrame = NSRect(x: 10, y: 0, width: 16, height: 16)
    private let cropRect = NSRect(x: 55, y: 0, width: 34, height: 55)
    
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
    
    func updateIcon(_ mark: CardMark) {
        switch mark {
        case .coin: icon = "coin"
        case .kept: icon = "kept"
        case .mulliganed: icon = "mulliganed"
        case .returned: icon = "returned"
        case .created: icon = "created"
        case .forged: icon = "card-icon-forged"
        case .drawnByEntity: icon = "card-icon-drawn"
        default: icon = nil
        }
    }
    
    func updateCardAge(_ cardAge: Int?) {
        if let cardAge {
            self.cardAge = cardAge
        } else {
            self.cardAge = nil
        }
    }
    
    func updateCostReduction(_ costReduction: Int) {
        if costReduction > 0 {
            self.costReduction = -costReduction
        } else {
            self.costReduction = nil
        }
    }
    
    func updateSourceCard(_ card: Card?) {
        if card == sourceCard {
            return
        }
        sourceCard = card
        if let card {
            ImageUtils.tile(for: card.id, completion: { img in
                self.sourceCardImage = img?.crop(rect: self.cropRect)
                DispatchQueue.main.async {
                    self.needsDisplay = true
                }
            })
        } else {
            sourceCardImage = nil
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        addImage(filename: "card-marker", rect: cardMarkerFrame)
        
        if let cardAge {
            let attributes = TextAttributes()
                .font(NSFont(name: "Belwe Bd BT", size: 20))
                .foregroundColor(.white)
                .strokeWidth(-2)
                .strokeColor(.black)
                .alignment(.center)
            NSAttributedString(string: "\(cardAge)", attributes: attributes)
                .draw(in: turnFrame)
        }
        
        if let costReduction {
            let costReductionAttributes = TextAttributes()
                .font(NSFont(name: "Belwe Bd BT", size: 16))
                .foregroundColor(Color(red: 0.117, green: 0.56, blue: 1, alpha: 1))
                .strokeWidth(-2)
                .strokeColor(.black)
            NSAttributedString(string: "\(costReduction)", attributes: costReductionAttributes)
                .draw(in: costReductionFrame)
        }
        
        if let sourceCardImage {
            self.addImage(image: sourceCardImage, rect: sourceCardFrame)
            let path = NSBezierPath(rect: sourceCardFrame)
            let color = NSColor(red: 0x14/0x100, green: 0x16/0x100, blue: 0x17/0x100, alpha: 1.0)
            color.set()
            path.stroke()
        }

        if let icon {
            addImage(filename: icon, rect: iconFrame)
        }
    }
    
    private func addImage(filename: String, rect: NSRect) {
        guard let image = NSImage(named: filename) else { return }
        image.draw(in: rect)
    }
    
    private func addImage(image: NSImage!, rect: NSRect) {
        image.draw(in: rect)
    }

    // MARK: - mouse hover
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        if !self.trackingAreas.contains(trackingArea) {
            self.addTrackingArea(trackingArea)
        }
    }

    override func mouseEntered(with event: NSEvent) {
        guard let card = self.sourceCard else { return }
        guard let rect = self.superview?.convert(self.frame, to: nil) else { return }
        guard let frame = self.superview?.window?.convertToScreen(rect) else { return }

        var screenRect = frame
        screenRect.origin.x += rect.width - 30
        screenRect.origin.y -= 250
        screenRect.size = NSSize(width: 200, height: 250)
        
        NotificationCenter.default
            .post(name: Notification.Name(rawValue: Events.show_floating_card),
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

    override func mouseExited(with event: NSEvent) {
        guard let sourceCard else { return }
 
        NotificationCenter.default
            .post(name: Notification.Name(rawValue: Events.hide_floating_card), object: nil, userInfo: [
                "card": sourceCard ])
    }
}
