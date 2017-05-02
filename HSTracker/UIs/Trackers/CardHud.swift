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
                              options: [.inVisibleRect, .activeAlways, .mouseEnteredAndExited],
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
        self.layer!.backgroundColor = NSColor.clear.cgColor
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        addImage(filename: "card-marker", rect: cardMarkerFrame)
        
        var text = ""
        var image: String? = nil
        var cost = 0
        card = nil
        
        if let entity = entity {
            text = "\(entity.info.turn)"
            
            switch entity.info.cardMark {
            case .coin: image = "coin"
            case .kept: image = "kept"
            case .mulliganed: image = "mulliganed"
            case .returned: image = "returned"
            case .created: image = "created"
            default: break
            }
            cost = entity.info.costReduction
            
            if entity.info.cardMark == .coin {
                card = Cards.any(byId: CardIds.NonCollectible.Neutral.TheCoin)
            } else if !entity.cardId.isBlank && !entity.info.hidden {
                image = "small-card"
                card = Cards.by(cardId: entity.cardId)
            }
        }
        if let image = image {
            addImage(filename: image, rect: iconFrame)
        }
        
        let attributes = TextAttributes()
            .font(NSFont(name: "Belwe Bd BT", size: 20))
            .foregroundColor(.white)
            .strokeWidth(-2)
            .strokeColor(.black)
            .alignment(.center)
        NSAttributedString(string: text, attributes: attributes)
            .draw(in: turnFrame)
        
        if cost > 0 {
            let costReductionAttributes = TextAttributes()
                .font(NSFont(name: "Belwe Bd BT", size: 16))
                .foregroundColor(Color(red: 0.117, green: 0.56, blue: 1, alpha: 1))
                .strokeWidth(-2)
                .strokeColor(.black)
            NSAttributedString(string: "-\(cost)", attributes: costReductionAttributes)
                .draw(in: costReductionFrame)
        }
    }
    
    private func addImage(filename: String, rect: NSRect) {
        guard let image = NSImage(named: filename) else { return }
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
        guard let card = self.card else { return }
        guard let rect = self.superview?.convert(self.frame, to: nil) else { return }
        guard let frame = self.superview?.window?.convertToScreen(rect) else { return }

        var screenRect = frame
        screenRect.origin.x += rect.width - 30
        screenRect.origin.y -= 250
        screenRect.size = NSSize(width: 200, height: 250)
        
        NotificationCenter.default
            .post(name: Notification.Name(rawValue: "show_floating_card"),
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
        guard card != nil else { return }
 
        NotificationCenter.default
            .post(name: Notification.Name(rawValue: "hide_floating_card"), object: nil)
    }
}
