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

protocol CardCellHover {
    func hover(card: Card)

    func out(card: Card)
}

class CardCellView: TrackerFrame {
    
    private let frameCountBoxRect = NSMakeRect(183, 0, 34, 34)
    private let frameCounterRect = NSMakeRect(195, 7, 18, 21)
    private let frameRect = NSMakeRect(0, 0, CGFloat(kFrameWidth), 34)
    private let gemRect = NSMakeRect(0, 0, 34, 34)
    private let imageRect = NSMakeRect(108, 4, 108, 27)
    private let fadeRect = NSMakeRect(28, 0, 189, 34)
    private let iconRect = NSMakeRect(183, 0, 34, 34)
    private let markerRect = NSMakeRect(192, 8, 21, 21)

    private var trackingArea: NSTrackingArea?
    var delegate: CardCellHover?
    var card: Card?
    var playerType: PlayerType?
    
    private var flashLayer: CALayer?
    private var cardLayer: CALayer?
    
    func update(highlight: Bool) {
        if highlight {
            let flashingLayer = CALayer()
            flashingLayer.frame = frameRect.ratio(ratio)
            flashingLayer.backgroundColor = NSColor(red: 1, green: 0.647, blue: 0, alpha: 1).CGColor
            
            let maskLayer = CALayer()
            maskLayer.frame = frameRect.ratio(ratio)
            maskLayer.contents = ImageCache.asset("frame_mask")
            flashingLayer.mask = maskLayer
            
            flashLayer?.addSublayer(flashingLayer)
            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 0.7
            fade.toValue = 0.0
            fade.duration = 0.5
            fade.removedOnCompletion = false
            fade.fillMode = kCAFillModeBoth
            flashingLayer.addAnimation(fade, forKey: "alpha")
        }
    }
    
    func fadeIn(fadeIn: Bool) {
    }
    
    func fadeOut(highlight: Bool) {
    }
    
    override func updateLayer() {
        if cardLayer == nil {
            cardLayer = CALayer()
            cardLayer?.frame = self.bounds
            layer?.addSublayer(cardLayer!)
        }
        
        if flashLayer == nil {
            flashLayer = CALayer()
            cardLayer?.frame = self.bounds
            layer?.addSublayer(flashLayer!)
        }
        
        if let cardLayer = cardLayer {
            cardLayer.sublayers?.forEach({ $0.removeFromSuperlayer() })
        }
        /*
        if let layer = self.layer, let sublayers = layer.sublayers {
            for sublayer in sublayers {
                sublayer.removeFromSuperlayer()
            }
        }*/
        guard let card = self.card else {return}
        
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
    
    private func addCardName(card: Card) {
        var foreground = NSColor.whiteColor()
        if self.playerType == .Player {
            foreground = card.textColor()
        }
        addText(card.name, NSMakeRect(38, -3, 174, 30), cardLayer, foreground)
    }

    private func addCardCost(card: Card) {
        let sublayer = CATextLayer()
        var foreground = NSColor.whiteColor()
        if self.playerType == .Player {
            foreground = card.textColor()
        }
        sublayer.string = NSAttributedString(string: "\(card.cost)", attributes: [
            NSFontAttributeName: NSFont(name: "Belwe Bd BT", size: 24 / ratio)!,
            NSForegroundColorAttributeName: foreground,
            NSStrokeWidthAttributeName: -2,
            NSStrokeColorAttributeName: NSColor.blackColor()
            ])
        
        sublayer.frame = NSMakeRect(card.cost > 9 ? 5.0 : 13.0, -4, 34, 37).ratio(ratio)
        cardLayer?.addSublayer(sublayer)
    }
    
    private func addDarken(card: Card) {
        addChild(ImageCache.darkenImage(), frameRect, cardLayer)
        if card.highlightFrame {
            addChild(ImageCache.frameImage(.Golden), frameRect, cardLayer)
            addChild(ImageCache.gemImage(.Legendary), gemRect, cardLayer)
            addCardCost(card)
        }
    }
    
    private func addFrameCounter(card: Card) {
        if Settings.instance.showRarityColors {
            addChild(ImageCache.frameCountbox(card.rarity), frameCountBoxRect, cardLayer)
        }
        else {
            addChild(ImageCache.frameCountbox(nil), frameCountBoxRect, cardLayer)
        }
        
        let count = abs(card.count)
        if count <= 1 && card.rarity == Rarity.Legendary {
            addChild(ImageCache.frameLegendary(), frameCountBoxRect, cardLayer)
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
            NSFontAttributeName: NSFont(name: "Belwe Bd BT", size: size / ratio)!,
            NSForegroundColorAttributeName: NSColor(red: 240.0 / 255.0, green: 195.0 / 255.0, blue: 72.0 / 255.0, alpha: 1.0),
            NSStrokeWidthAttributeName: -2,
            NSStrokeColorAttributeName: NSColor.blackColor()
        ])
        sublayer.frame = NSMakeRect(x, y, 30, 37).ratio(ratio)
        cardLayer?.addSublayer(sublayer)
    }
    
    private func addGem(card: Card) {
        if card.highlightFrame {
            addChild(ImageCache.gemImage(.Legendary), gemRect, cardLayer)
        }
        else if Settings.instance.showRarityColors {
            addChild(ImageCache.gemImage(card.rarity), gemRect, cardLayer)
        }
        else {
            addChild(ImageCache.gemImage(nil), gemRect, cardLayer)
        }
    }

    private func addCardImage(card:Card) {
        let xOffset:CGFloat = abs(card.count) > 1 || card.rarity == .Legendary ? 19 : 0
        addChild(ImageCache.smallCardImage(card), imageRect.offsetBy(dx: -xOffset, dy: 0), cardLayer)
        addChild(ImageCache.fadeImage(), fadeRect.offsetBy(dx: -xOffset, dy: 0), cardLayer)
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
        addChild(frame, frameRect, cardLayer)
    }
    
    // MARK: - CardCellHover
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
        if let card = self.card {
            delegate?.hover(card)
        }
    }

    override func mouseExited(event: NSEvent) {
        if let card = self.card {
            delegate?.out(card)
        }
    }
}
