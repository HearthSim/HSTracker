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

protocol CardCellHover {
    func hover(card: Card)

    func out(card: Card)
}

class CardCellView: NSTableCellView {
    var cardLayer: CALayer = CALayer()
    var frameLayer: CALayer = CALayer()
    var gemLayer: CALayer = CALayer()
    var costLayer: CATextLayer = CATextLayer()
    var textLayer: CATextLayer = CATextLayer()
    var frameCountBox: CALayer = CALayer()
    var extraInfo: CALayer = CALayer()
    var flashLayer: CALayer = CALayer()
    var maskLayer: CALayer = CALayer()

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

        // the layer for the card art
        self.layer!.addSublayer(cardLayer)

        // the layer for the frame
        self.layer!.addSublayer(frameLayer)

        // the layer for the gem art
        self.layer!.addSublayer(gemLayer)

        costLayer.contentsScale = NSScreen.mainScreen()!.backingScaleFactor
        self.layer!.addSublayer(costLayer)

        textLayer.contentsScale = NSScreen.mainScreen()!.backingScaleFactor
        self.layer!.addSublayer(textLayer)

        self.layer!.addSublayer(frameCountBox)

        self.layer!.addSublayer(extraInfo)

        // the layer for flashing the card on draw
        self.layer!.addSublayer(flashLayer)

        maskLayer.contents = ImageCache.frameImageMask()
    }

    override func updateLayer() {
        let settings = Settings.instance
        var alpha: Float
        var showAlpha: Bool
        if let card = self.card {
            if self.playerType == .Player {
                showAlpha = card.count == 0
                if !settings.inHandAsPlayed {
                    showAlpha = showAlpha && card.handCount <= 0
                }

                alpha = (showAlpha) ? 0.4 : 1.0
            } else {
                alpha = card.count == 0 ? 0.4 : 1.0
            }

            var ratio: Double
            switch settings.cardSize {
            case .Small:
                ratio = KRowHeight / KSmallRowHeight

            case .Medium:
                ratio = KRowHeight / KMediumRowHeight

            default:
                ratio = 1.0
            }

            // draw the card art
            cardLayer.contents = ImageCache.smallCardImage(card)
            var x = 104.0 / ratio
            var y = 1.0 / ratio
            var width = 110.0 / ratio
            var height = 34.0 / ratio
            cardLayer.frame = NSRect(x: x, y: y, width: width, height: height)
            cardLayer.opacity = alpha

            if settings.showRarityColors {
                gemLayer.contents = ImageCache.gemImage(card.rarity)
            } else {
                gemLayer.contents = nil
            }
            x = 3.0 / ratio
            y = 4.0 / ratio
            width = 28.0 / ratio
            height = 28.0 / ratio
            gemLayer.frame = NSRect(x: x, y: y, width: width, height: height)
            gemLayer.opacity = alpha

            // draw the frame
            if card.isStolen {
                frameLayer.contents = ImageCache.frameDeckImage()
            } else {
                frameLayer.contents = ImageCache.frameImage(card.rarity)
            }
            x = 1.0 / ratio
            y = 0.0 / ratio
            width = 218.0 / ratio
            height = 35.0 / ratio
            let frameRect = NSRect(x: x, y: y, width: width, height: height)
            frameLayer.frame = frameRect
            frameLayer.opacity = alpha

            // print the card name
            let strokeColor = NSColor(red: 0, green: 0, blue: 0, alpha: CGFloat(alpha))
            var foreground = NSColor(red: 255, green: 255, blue: 255, alpha: CGFloat(alpha))
            if card.handCount > 0 && self.playerType == .Player {
                foreground = settings.flashColor.colorWithAlphaComponent(CGFloat(alpha))
            }

            var nameFont: NSFont
            if settings.isCyrillicOrAsian {
                nameFont = NSFont(name: "NanumGothic", size: CGFloat(18.0 / ratio))!
            } else {
                nameFont = NSFont(name: "Belwe Bd BT", size: CGFloat(15.0 / ratio))!
            }

            let name = NSAttributedString(string: card.name, attributes: [
                    NSFontAttributeName: nameFont,
                    NSForegroundColorAttributeName: foreground,
                    NSStrokeWidthAttributeName: settings.isCyrillicOrAsian ? 0 : -2,
                    NSStrokeColorAttributeName: settings.isCyrillicOrAsian ? NSColor.clearColor() : strokeColor
            ])
            x = 38.0 / ratio
            y = -3.0 / ratio
            width = 174.0 / ratio
            height = 30.0 / ratio
            textLayer.frame = NSRect(x: x, y: y, width: width, height: height)
            textLayer.opacity = alpha
            textLayer.string = name

            let cardCost = card.cost
            // print the card cost
            let costFont = NSFont(name: "Belwe Bd BT", size: CGFloat(22.0 / ratio))!
            let cost = NSAttributedString(string: "\(cardCost)",
                    attributes: [
                            NSFontAttributeName: costFont,
                            NSForegroundColorAttributeName: foreground,
                            NSStrokeWidthAttributeName: -1.5,
                            NSStrokeColorAttributeName: strokeColor
                    ])
            x = (cardCost > 9 ? 6.0 : 13.0) / ratio
            y = -4.0 / ratio
            width = 34.0 / ratio
            height = 37.0 / ratio

            costLayer.frame = NSRect(x: x, y: y, width: width, height: height)
            costLayer.string = cost

            // by default, we only show 2 or more
            let minCount = settings.showOneCard ? 1 : 2

            if card.count > minCount || card.rarity == "legendary" {
                // add the background of the card count
                if card.isStolen {
                    frameCountBox.contents = ImageCache.frameCountboxDeck()
                } else {
                    frameCountBox.contents = ImageCache.frameCountbox()
                }
                x = 189.0 / ratio
                y = 5.0 / ratio
                width = 25.0 / ratio
                height = 24.0 / ratio
                frameCountBox.frame = NSRect(x: x, y: y, width: width, height: height)

                if (card.count > minCount && card.count < 9) && card.rarity != "legendary" {
                    // the card count
                    extraInfo.contents = ImageCache.frameCount(card.count)
                } else {
                    // card is legendary (or count > 10)
                    extraInfo.contents = ImageCache.frameLegendary()
                }
                x = 194.0 / ratio
                y = 8.0 / ratio
                width = 18.0 / ratio
                height = 21.0 / ratio
                extraInfo.frame = NSRect(x: x, y: y, width: width, height: height)
            } else {
                extraInfo.contents = nil
                frameCountBox.contents = nil
            }
            frameCountBox.opacity = alpha
            extraInfo.opacity = alpha

            flashLayer.frame = self.bounds
            maskLayer.frame = frameRect
            flashLayer.mask = maskLayer
        }
    }

    func setDelegate(delegate: CardCellHover) {
        self.delegate = delegate
    }

    func flash() {
        flashLayer.backgroundColor = Settings.instance.flashColor.CGColor
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 0.7
        fade.toValue = 0.0
        fade.duration = 0.5

        fade.removedOnCompletion = false
        fade.fillMode = kCAFillModeBoth

        flashLayer.addAnimation(fade, forKey: "alpha")
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
        if let delegate = self.delegate {
            if let card = self.card {
                delegate.hover(card)
            }
        }
    }

    override func mouseExited(event: NSEvent) {
        if let delegate = self.delegate {
            if let card = self.card {
                delegate.out(card)
            }
        }
    }

}
