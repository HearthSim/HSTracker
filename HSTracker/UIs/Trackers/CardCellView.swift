/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 15/02/16.
 */

import Cocoa
import QuartzCore

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

protocol CardCellHover {
    func hover(card: Card)

    func out(card: Card)
}

extension NSRect {
    func ratio(ratio: CGFloat) -> NSRect {
        return NSMakeRect(self.origin.x / ratio,
                          self.origin.y / ratio,
                          self.size.width / ratio,
                          self.size.height / ratio)
    }
}

class CardCellView: NSView {
    
    let frameCountBoxRect = NSMakeRect(183, 0, 34, 34)
    let frameCounterRect = NSMakeRect(195, 7, 18, 21)
    let frameRect = NSMakeRect(0, 0, 217, 34)
    let gemRect = NSMakeRect(0, 0, 34, 34)
    let imageRect = NSMakeRect(108, 4, 108, 27)
    let fadeRect = NSMakeRect(28, 0, 189, 34)
    let iconRect = NSMakeRect(183, 0, 34, 34)
    let markerRect = NSMakeRect(192, 8, 21, 21)

    var trackingArea: NSTrackingArea?
    var delegate: CardCellHover?
    var card: Card?
    var playerType: PlayerType?

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
    
    override func updateLayer() {
        if let layer = self.layer, let sublayers = layer.sublayers {
            for sublayer in sublayers {
                sublayer.removeFromSuperlayer()
            }
        }
        
        if let card = self.card {
            addCardImage(card)
            addCardName(card)
            addFrame(card)
            
            addGem(card)
            
            if abs(card.count) > 1 || card.rarity == Rarity.Legendary {
                addFrameCounter(card)
            }
            addCardCost(card)
            
            if card.count <= 0 || card.jousted {
                addDarken(card)
            }
        }
    }
    
    private func addCardName(card: Card) {
        let sublayer = CATextLayer()
        var foreground = NSColor.whiteColor()
        if self.playerType == .Player {
            foreground = card.textColor()
        }
        sublayer.string = NSAttributedString(string: card.name, attributes: [
            NSFontAttributeName: NSFont(name: "Belwe Bd BT", size: 16 / self.ratio())!,
            NSForegroundColorAttributeName: foreground,
            NSStrokeWidthAttributeName: -2,
            NSStrokeColorAttributeName: NSColor.blackColor()
            ])
        sublayer.frame = NSMakeRect(38 / self.ratio(), -3 / self.ratio(), 174 / self.ratio(), 30 / self.ratio())
        self.layer?.addSublayer(sublayer)
    }
    
    private func addCardCost(card: Card) {
        let sublayer = CATextLayer()
        var foreground = NSColor.whiteColor()
        if self.playerType == .Player {
            foreground = card.textColor()
        }
        sublayer.string = NSAttributedString(string: "\(card.cost)", attributes: [
            NSFontAttributeName: NSFont(name: "Belwe Bd BT", size: 24 / self.ratio())!,
            NSForegroundColorAttributeName: foreground,
            NSStrokeWidthAttributeName: -2,
            NSStrokeColorAttributeName: NSColor.blackColor()
            ])
        
        sublayer.frame = NSMakeRect((card.cost > 9 ? 5.0 : 13.0) / self.ratio(),
                                    -4 / self.ratio(),
                                    34 / self.ratio(),
                                    37 / self.ratio())
        self.layer?.addSublayer(sublayer)
    }
    
    private func addDarken(card: Card) {
        addChild(ImageCache.darkenImage(), frameRect)
        if card.highlightFrame {
            addChild(ImageCache.frameImage(.Golden), frameRect)
            addChild(ImageCache.gemImage(.Legendary), gemRect)
            addCardCost(card)
        }
    }
    
    private func addFrameCounter(card: Card) {
        if Settings.instance.showRarityColors {
            addChild(ImageCache.frameCountbox(card.rarity), frameCountBoxRect)
        }
        else {
            addChild(ImageCache.frameCountbox(nil), frameCountBoxRect)
        }
        
        let count = abs(card.count)
        if count <= 1 && card.rarity == Rarity.Legendary {
            addChild(ImageCache.frameLegendary(), frameCountBoxRect)
        }
        else {
            let countText = count > 9 ? "9" : "\(count)"
            addText(countText, 20, 198, -6)
            if count > 9 {
                addText("+", 13, 202, -6)
            }
        }
    }
    
    private func addText(text: String, _ size: CGFloat, _ x: CGFloat, _ y: CGFloat) {
        let sublayer = CATextLayer()
        sublayer.string = NSAttributedString(string: text, attributes: [
            NSFontAttributeName: NSFont(name: "Belwe Bd BT", size: size / self.ratio())!,
            NSForegroundColorAttributeName: NSColor(red: 240.0 / 255.0, green: 195.0 / 255.0, blue: 72.0 / 255.0, alpha: 1.0),
            NSStrokeWidthAttributeName: -2,
            NSStrokeColorAttributeName: NSColor.blackColor()
        ])
        sublayer.frame = NSMakeRect(x / self.ratio(), y / self.ratio(), 30 / self.ratio(), 37 / self.ratio())
        self.layer?.addSublayer(sublayer)
    }
    
    private func addGem(card: Card) {
        if card.highlightFrame {
            addChild(ImageCache.gemImage(.Legendary), gemRect)
        }
        else if Settings.instance.showRarityColors {
            addChild(ImageCache.gemImage(card.rarity), gemRect)
        }
        else {
            addChild(ImageCache.gemImage(nil), gemRect)
        }
    }

    private func ratio() -> CGFloat {
        var ratio: CGFloat
        if self.playerType == .DeckManager {
            ratio = 1.0
        } else {
            switch Settings.instance.cardSize {
            case .Small:
                ratio = CGFloat(kRowHeight / kSmallRowHeight)
            
            case .Medium:
                ratio = CGFloat(kRowHeight / kMediumRowHeight)
            
            default:
                ratio = 1.0
            }
        }
        return ratio
    }

    private func addChild(image: NSImage?, _ rect:NSRect) {
        guard let _ = image else { return }
        
        let sublayer = CALayer()
        sublayer.contents = image!
        sublayer.frame = rect.ratio(self.ratio())
        self.layer?.addSublayer(sublayer)
    }
    
    private func addCardImage(card:Card) {
        let xOffset:CGFloat = abs(card.count) > 1 || card.rarity == .Legendary ? 19 : 0
        addChild(ImageCache.smallCardImage(card), imageRect.offsetBy(dx: -xOffset, dy: 0))
        addChild(ImageCache.fadeImage(), fadeRect.offsetBy(dx: -xOffset, dy: 0))
    }
    
    private func addFrame(card:Card) {
        var frame = ImageCache.frameImage(nil)
        if card.highlightFrame {
            frame = ImageCache.frameImage(.Golden)
        }
        else {
            if Settings.instance.showRarityColors {
                frame = ImageCache.frameImage(card.rarity)
            }
        }
        addChild(frame, frameRect)
    }
    
    func setDelegate(delegate: CardCellHover) {
        self.delegate = delegate
    }

    // MARK: - mouse hover
    func ensureTrackingArea() {
        if trackingArea == nil {
            trackingArea = NSTrackingArea(rect: NSZeroRect,
                options: [NSTrackingAreaOptions.InVisibleRect, NSTrackingAreaOptions.ActiveAlways, NSTrackingAreaOptions.MouseEnteredAndExited],
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
        if let delegate = self.delegate, card = self.card {
            delegate.hover(card)
        }
    }

    override func mouseExited(event: NSEvent) {
        if let delegate = self.delegate, card = self.card {
            delegate.out(card)
        }
    }
}
