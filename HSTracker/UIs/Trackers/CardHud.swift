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

class CardHud: NSWindowController {

    @IBOutlet weak var hud: CardHudHoverView!
    var entity: Entity?
    var card: Card?
    var floatingCard: FloatingCard?

    @IBOutlet weak var label: NSTextFieldCell!
    @IBOutlet weak var icon: NSImageView!
    @IBOutlet weak var costReduction: NSTextField!

    override func windowDidLoad() {
        super.windowDidLoad()

        self.window!.styleMask = NSBorderlessWindowMask
        self.window!.ignoresMouseEvents = true
        self.window!.acceptsMouseMovedEvents = true
        self.window!.level = Int(CGWindowLevelForKey(CGWindowLevelKey.ScreenSaverWindowLevelKey))

        self.window!.opaque = false
        self.window!.hasShadow = false
        self.window!.backgroundColor = NSColor.clearColor()

        hud.setDelegate(self)

        NSNotificationCenter.defaultCenter()
            .addObserver(self,
                         selector: #selector(CardHud.hearthstoneActive(_:)),
                         name: "hearthstone_active",
                         object: nil)
    }

    func hearthstoneActive(notification: NSNotification) {
        let hs = Hearthstone.instance

        let level: Int
        if hs.hearthstoneActive {
            level = Int(CGWindowLevelForKey(CGWindowLevelKey.ScreenSaverWindowLevelKey))
        } else {
            level = Int(CGWindowLevelForKey(CGWindowLevelKey.NormalWindowLevelKey))
        }
        self.window!.level = level
    }

    func setEntity(entity: Entity?) {
        self.entity = entity
        var text = ""
        var image: String? = nil
        var cost = 0

        if let entity = entity {
            text += "\(entity.info.turn)"

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
                card = Cards.anyById(CardIds.NonCollectible.Neutral.TheCoin)
            } else if !String.isNullOrEmpty(entity.cardId) && !entity.info.hidden {
                image = "small-card"
                card = Cards.byId(entity.cardId)
            }
        }
        let attributes = TextAttributes()
            .font(NSFont(name: "Belwe Bd BT", size: 20))
            .foregroundColor(NSColor.whiteColor())
            .strokeWidth(-2)
            .strokeColor(NSColor.blackColor())
            .alignment(.Center)
        label.attributedStringValue = NSAttributedString(string: text, attributes: attributes)

        let costReductionAttributes = TextAttributes()
            .font(NSFont(name: "Belwe Bd BT", size: 16))
            .foregroundColor(NSColor(red: 0.117, green: 0.56, blue: 1, alpha: 1))
            .strokeWidth(-2)
            .strokeColor(NSColor.blackColor())

        costReduction.attributedStringValue = NSAttributedString(
            string: "-\(cost)",
            attributes: costReductionAttributes)

        costReduction.hidden = cost < 1
        if let image = image {
            icon.image = ImageCache.asset(image)
        } else {
            icon.image = nil
        }
    }

    // MARK: - mouse hover
    func hover() {
        if let card = self.card, windowFrame = self.window?.frame {
            let frame = [windowFrame.origin.x + NSWidth(windowFrame) - 30,
                                   windowFrame.origin.y - 250,
                                   200, 303]

            NSNotificationCenter.defaultCenter()
                .postNotificationName("show_floating_card",
                                      object: nil,
                                      userInfo: [
                                        "card": card,
                                        "frame": frame
                    ])
        }
    }

    func out() {
        if let _ = self.card {
            NSNotificationCenter.defaultCenter()
                .postNotificationName("hide_floating_card", object: nil)
        }
    }
}

class CardHudHoverView: NSView {
    private var _delegate: CardHud?
    private var trackingArea: NSTrackingArea?

    func setDelegate(delegate: CardHud?) {
        self._delegate = delegate
    }

    // MARK: - mouse hover
    func ensureTrackingArea() {
        if trackingArea == nil {
            trackingArea = NSTrackingArea(rect: NSZeroRect,
                                          options: [NSTrackingAreaOptions.InVisibleRect,
                                            NSTrackingAreaOptions.ActiveAlways,
                                            NSTrackingAreaOptions.MouseEnteredAndExited],
                                          owner: self,
                                          userInfo: nil)
        }
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        ensureTrackingArea()

        if !self.trackingAreas.contains(trackingArea!) {
            self.addTrackingArea(trackingArea!)
        }
    }

    override func mouseEntered(event: NSEvent) {
        _delegate?.hover()
    }

    override func mouseExited(event: NSEvent) {
        _delegate?.out()
    }
}
