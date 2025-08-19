//
//  ActiveEffect.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/8/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class ActiveEffect: NSView {
    
    @IBOutlet var contentView: NSView!
    
    @IBOutlet var outerBorder: NSBox!
    @IBOutlet var innerBorder: NSBox!
    
    let effect: EntityBasedEffect
    @objc dynamic var count: NSNumber?
    @IBOutlet var countLabel: NSTextField!
    var isPlayer: Bool
    
    private var _image: NSImage?
    @objc dynamic var cardImage: NSImage? {
        if let image = _image {
            return image
        }
        if let cardId = effect.cardIdToShowInUI {
            ImageUtils.art(for: cardId, completion: { image in
                DispatchQueue.main.async {
                    self.willChangeValue(forKey: "cardImage")
                    self._image = image
                    self.didChangeValue(forKey: "cardImage")
                }
            })
        }
        return nil
    }
    
    override var intrinsicContentSize: NSSize {
        return NSSize(width: 61, height: 61)
    }
    
    init(_ effect: EntityBasedEffect, _ isPlayer: Bool, _ count: Int? = nil) {
        self.effect = effect
        if let count {
            self.count = count as NSNumber
        } else {
            self.count = nil
        }
        self.isPlayer = isPlayer
        
        super.init(frame: NSRect(x: 0, y: 0, width: 61, height: 61))

        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        NibHelper.loadNib(Self.self, self)
        
        translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        
        let isControlledByPlayer = effect.isControlledByPlayer
        
        outerBorder.borderColor = isControlledByPlayer ? NSColor.fromHexString(hex: "#29293d")! : NSColor.fromHexString(hex: "#e39d91")!
        innerBorder.borderColor = isControlledByPlayer ? NSColor.fromHexString(hex: "#8c7ca3")! : NSColor.fromHexString(hex: "#671e14")!
        
        countLabel.chunkFive()
    }
    
    private lazy var trackingArea: NSTrackingArea = {
        return NSTrackingArea(rect: self.bounds,
                              options: [.inVisibleRect, .activeAlways, .mouseEnteredAndExited],
                              owner: self,
                              userInfo: nil)
    }()

    // MARK: - mouse hover
    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if !self.trackingAreas.contains(trackingArea) {
            self.addTrackingArea(trackingArea)
        }
    }
    
    var delayedTooltip: DelayedTooltip?

    override func mouseEntered(with event: NSEvent) {
        if let card = effect.cardToShowInUI, window != nil {
            delayedTooltip = DelayedTooltip(handler: tooltipDisplay, 0.400, card)
        }
    }

    override func mouseExited(with event: NSEvent) {
        guard let card = effect.cardToShowInUI else {
            return
        }
        delayedTooltip?.cancel()
        delayedTooltip = nil
        
        let userinfo = [
            "card": card
        ] as [String: Any]
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: Events.hide_floating_card),
                                        object: nil,
                                        userInfo: userinfo)
    }
    
    private func tooltipDisplay(_ userInfo: Any?) {
        if let window, let card = userInfo as? Card {
            let windowRect = window.frame
            
            let hoverFrame = NSRect(x: 0, y: 0, width: 256, height: 388)
            
            var x: CGFloat
            if windowRect.origin.x < hoverFrame.size.width {
                x = windowRect.origin.x + windowRect.size.width
            } else {
                x = windowRect.origin.x - hoverFrame.size.width
            }
            
            let cellFrameRelativeToWindow = self.convert(self.bounds, to: nil)
            let cellFrameRelativeToScreen = window.convertToScreen(cellFrameRelativeToWindow)
            
            let y: CGFloat = cellFrameRelativeToScreen.origin.y
            
            let frame: [CGFloat] = [x, y - hoverFrame.height / 2.0, hoverFrame.width, hoverFrame.height]
            NotificationCenter.default
                .post(name: Notification.Name(rawValue: Events.show_floating_card),
                      object: nil,
                      userInfo: [
                        "card": card,
                        "frame": frame,
                        "useFrame": true
                      ])
        }
    }
}
