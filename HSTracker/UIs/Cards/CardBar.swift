//
//  CardBar.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 31/05/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger
import TextAttributes

protocol CardCellHover {
    func hover(cell: CardBar, card: Card)

    func out(card: Card)
}

protocol CardBarTheme {
    var card: Card? {get set}
    var playerType: PlayerType? {get set}
}

class CardBar: NSView, CardBarTheme {
    private var trackingArea: NSTrackingArea?
    private var delegate: CardCellHover?

    private var flashLayer: CALayer?
    private var cardLayer: CALayer?

    class func factory() -> CardBar {
        switch Settings.instance.theme {
        case "frost":
            return FrostBar()
        case "dark":
            return DarkBar()
        case "minimal":
            return MinimalBar()
        default:
            return ClassicBar()
        }
    }

    var themeDir: String {
        return ""
    }

    private var oldCard: Card?
    var card: Card? {
        didSet {
            oldCard = oldValue
        }
    }
    var playerType: PlayerType?

    var hasAllRequired: Bool {
        let path = NSBundle.mainBundle().resourcePath!
            + "/Resources/Themes/Bars/\(themeDir)/"
        let manager = NSFileManager.defaultManager()
        return required.map { $0.1 } .all {
            manager.fileExistsAtPath("\(path)\($0.filename)")
        }
    }
    var hasAllOptionalFrames: Bool {
        let path = NSBundle.mainBundle().resourcePath!
            + "/Resources/Themes/Bars/\(themeDir)/"
        let manager = NSFileManager.defaultManager()
        return optionalFrame.map { $0.1 } .all {
            manager.fileExistsAtPath("\(path)\($0.filename)")
        }
    }

    var hasAllOptionalGems: Bool {
        let path = NSBundle.mainBundle().resourcePath!
            + "/Resources/Themes/Bars/\(themeDir)/"
        let manager = NSFileManager.defaultManager()
        return optionalGems.map { $0.1 } .all {
            manager.fileExistsAtPath("\(path)\($0.filename)")
        }
    }

    var hasAllOptionalCountBoxes: Bool {
        let path = NSBundle.mainBundle().resourcePath!
            + "/Resources/Themes/Bars/\(themeDir)/"
        let manager = NSFileManager.defaultManager()
        return optionalCountBoxes.map { $0.1 } .all {
            manager.fileExistsAtPath("\(path)\($0.filename)")
        }
    }

    var fadeOffset: CGFloat = -23
    var imageOffset: CGFloat = -23
    var createdIconOffset: CGFloat = -23

    var countFontSize: CGFloat = 17
    var textFontSize: CGFloat = 15
    var costFontSize: CGFloat = 20
    var flashColor: NSColor {
        return NSColor.whiteColor()
    }

    let frameRect = NSRect(x: 0, y: 0, width: 217, height: 34)
    let gemRect = NSRect(x: 0, y: 0, width: 34, height: 34)
    let boxRect = NSRect(x: 183, y: 0, width: 34, height: 34)
    let imageRect = NSRect(x: 83, y: 0, width: 134, height: 34)
    let countTextRect = NSRect(x: 198, y: 9, width: CGFloat.max, height: 34)
    let costTextRect = NSRect(x: 0, y: 9, width: 34, height: 34)

    var countTextColor: NSColor {
        return NSColor ( red: 0.9221, green: 0.7215, blue: 0.2226, alpha: 1.0 )
    }
    var numbersFont: String {
        return "ChunkFive"
    }
    var textFont: String {
        if Settings.instance.isAsianLanguage {
            return "NanumGothic"
        } else if Settings.instance.isCyrillicLanguage {
            return "Benguiat Rus"
        } else {
            return "ChunkFive"
        }
    }

    var required: [ThemeElement: ThemeElementInfo] {
        return [
            .DefaultFrame: ThemeElementInfo(filename: "frame.png", rect: frameRect),
            .DefaultGem: ThemeElementInfo(filename: "gem.png", rect: gemRect),
            .DefaultCountBox: ThemeElementInfo(filename: "countbox.png", rect: boxRect),
            .DarkOverlay: ThemeElementInfo(filename: "dark.png", rect: frameRect),
            .FadeOverlay: ThemeElementInfo(filename: "fade.png", rect: frameRect),
            .CreatedIcon: ThemeElementInfo(filename: "icon_created.png", rect: boxRect),
            .LegendaryIcon: ThemeElementInfo(filename: "icon_legendary.png", rect: boxRect),
            .FlashFrame: ThemeElementInfo(filename: "frame_mask.png", rect: frameRect),
        ]
    }
    var optionalFrame: [ThemeElement: ThemeElementInfo] {
        return [
            .CommonFrame: ThemeElementInfo(filename: "frame_common.png", rect: frameRect),
            .RareFrame: ThemeElementInfo(filename: "frame_rare.png", rect: frameRect),
            .EpicFrame: ThemeElementInfo(filename: "frame_epic.png", rect: frameRect),
            .LegendaryFrame: ThemeElementInfo(filename: "frame_legendary.png", rect: frameRect)
        ]
    }

    var optionalGems: [ThemeElement: ThemeElementInfo] {
        return [
            .CommonGem: ThemeElementInfo(filename: "gem_common.png", rect: gemRect),
            .RareGem: ThemeElementInfo(filename: "gem_rare.png", rect: gemRect),
            .EpicGem: ThemeElementInfo(filename: "gem_epic.png", rect: gemRect),
            .LegendaryGem: ThemeElementInfo(filename: "gem_legendary.png", rect: gemRect),
        ]
    }

    var optionalCountBoxes: [ThemeElement: ThemeElementInfo] {
        return [
            .CommonCountBox: ThemeElementInfo(filename: "countbox_common.png", rect: boxRect),
            .RareCountBox: ThemeElementInfo(filename: "countbox_rare.png", rect: boxRect),
            .EpicCountBox: ThemeElementInfo(filename: "countbox_epic.png", rect: boxRect),
            .LegendaryCountBox: ThemeElementInfo(filename: "countbox_legendary.png", rect: boxRect)
        ]
    }

    init() {
        super.init(frame: NSZeroRect)
        initLayers()
        initVars()
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        initLayers()
        initVars()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initLayers()
        initVars()
    }

    func initVars() {}

    func initLayers() {
        self.wantsLayer = true

        layer?.backgroundColor = NSColor.clearColor().CGColor
        cardLayer = CALayer()
        cardLayer?.frame = self.bounds
        if let cardLayer = cardLayer {
            layer?.addSublayer(cardLayer)
        }

        flashLayer = CALayer()
        flashLayer?.frame = self.bounds
        if let flashLayer = flashLayer {
            layer?.addSublayer(flashLayer)
        }
    }

    func update(highlight: Bool) {
        if highlight && Settings.instance.flashOnDraw {
            if let themeElement = required[.FlashFrame] {
                let fullPath = NSBundle.mainBundle().resourcePath!
                    + "/Resources/Themes/Bars/\(themeDir)/\(themeElement.filename)"
                if let image = NSImage(contentsOfFile: fullPath)
                    where NSFileManager.defaultManager().fileExistsAtPath(fullPath) {
                    let flashingLayer = CALayer()
                    flashingLayer.frame = ratio(frameRect)
                    flashingLayer.backgroundColor = flashColor.CGColor

                    let maskLayer = CALayer()
                    maskLayer.frame = ratio(frameRect)
                    maskLayer.contents = image
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
        }
    }

    // MARK: - animation
    func fadeIn(fadeIn: Bool) {
    }

    func fadeOut(highlight: Bool) {
    }

    // MARK: - drawing
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        guard let card = card else { return }
        guard hasAllRequired else { return }

        if areEquals(card, oldCard) { return }

        cardLayer?.sublayers?.forEach { $0.removeFromSuperlayer() }

        addCardImage()
        addFadeOverlay()

        if abs(card.count) > 1 || card.rarity == .Legendary {
            addCountBox()
            addCountText()
        }
        if card.isCreated {
            addCreatedIcon()
        }
        if abs(card.count) <= 1 && card.rarity == .Legendary {
            addLegendaryIcon()
        }
        addFrame()
        addGem()
        addCost()
        addCardName()
        if (card.count <= 0 || card.jousted) && playerType != .CardList {
            addDarken()
        }
    }

    func addCardImage() {
        addCardImage(imageRect)
    }
    func addCardImage(rect: NSRect, offsetByCountBox: Bool = false) {
        guard let card = card else { return }

        let fullPath = NSBundle.mainBundle().resourcePath! + "/Resources/Small/\(card.id).png"
        if let image = NSImage(contentsOfFile: fullPath) {
            if offsetByCountBox && abs(card.count) > 1 || card.rarity == .Legendary {
                addChild(image, rect: rect.offsetBy(dx: imageOffset, dy: 0))
            } else {
                addChild(image, rect: rect)
            }
        }
    }

    func addFadeOverlay() {
        if let rect = required[.FadeOverlay]?.rect {
            addFadeOverlay(rect)
        }
    }
    func addFadeOverlay(rect: NSRect, offsetByCountBox: Bool = false) {
        guard let card = card else { return }

        if let fadeOverlay = required[.FadeOverlay] {
            if offsetByCountBox && (abs(card.count) > 1 || card.rarity == .Legendary) {
                addChild(fadeOverlay, rect: rect.offsetBy(dx: fadeOffset, dy: 0))
            } else {
                addChild(fadeOverlay, rect: rect)
            }
        }
    }

    func addCountBox() {
        guard let card = card else { return }

        var countBox = required[.DefaultCountBox]
        if Settings.instance.showRarityColors && hasAllOptionalCountBoxes {
            switch card.rarity {
            case .Rare:
                countBox = optionalCountBoxes[.RareCountBox]
            case .Epic:
                countBox = optionalCountBoxes[.EpicCountBox]
            case .Legendary:
                countBox = optionalCountBoxes[.LegendaryCountBox]
            default:
                countBox = optionalCountBoxes[.CommonCountBox]
            }
        }

        if let countBox = countBox {
            addChild(countBox)
        }
    }

    func addCountText() {
        addCountText(countTextRect)
    }
    func addCountText(rect: NSRect) {
        guard let card = card else { return }

        let  count = abs(card.count)
        guard count > 1 else { return }

        addText(min(count, 9), fontSize: countFontSize,
                rect: rect, textColor: countTextColor, font: numbersFont)
        if count > 9 {
            addText("+", fontSize: 13,
                    rect: NSRect(x: rect.origin.x + 5, y: 3,
                        width: CGFloat.max, height: CGFloat.max),
                    textColor: countTextColor, font: textFont)
        }
    }

    func addCreatedIcon() {
        if let rect = required[.CreatedIcon]?.rect {
            addCreatedIcon(rect)
        }
    }
    func addCreatedIcon(rect: NSRect) {
        guard let card = card else { return }

        if let createdIcon = required[.CreatedIcon] {
            if abs(card.count) > 1 || card.rarity == .Legendary {
                addChild(createdIcon, rect: rect.offsetBy(dx: createdIconOffset, dy: 0))
            } else {
                addChild(createdIcon, rect: rect)
            }
        }
    }

    func addLegendaryIcon() {
        if let rect = required[.LegendaryIcon]?.rect {
            addLegendaryIcon(rect)
        }
    }
    func addLegendaryIcon(rect: NSRect) {
        if let icon = required[.LegendaryIcon] {
            addChild(icon, rect: rect)
        }
    }

    func addFrame() {
        guard let card = card else { return }

        var frame = required[.DefaultFrame]
        if Settings.instance.showRarityColors && hasAllOptionalFrames {
            switch card.rarity {
            case .Rare:
                frame = optionalFrame[.RareFrame]
            case .Epic:
                frame = optionalFrame[.EpicFrame]
            case .Legendary:
                frame = optionalFrame[.LegendaryFrame]
            default:
                frame = optionalFrame[.CommonFrame]
                break
            }
        }

        if let frame = frame {
            addChild(frame)
        }
    }

    func addGem() {
        guard let card = card else { return }

        var gem = required[.DefaultGem]
         if Settings.instance.showRarityColors && hasAllOptionalGems {
            switch card.rarity {
            case .Rare:
                gem = optionalGems[.RareGem]
            case .Epic:
                gem = optionalGems[.EpicGem]
            case Rarity.Legendary:
                gem = optionalGems[.LegendaryGem]
            default:
                gem = optionalGems[.CommonGem]
            }
        }

        if let gem = gem {
            addChild(gem)
        }
    }

    func addCost() {
        addCost(costTextRect)
    }
    func addCost(rect: NSRect) {
        guard let card = card else { return }

        var textColor = card.textColor()
        if playerType == .CardList {
            textColor = NSColor.whiteColor()
        }

        addText(card.cost, fontSize: costFontSize, rect: rect,
                textColor: textColor, font: numbersFont,
                strokeThickness: -1.0, centered: true)
    }

    func addCardName() {
        addCardName(NSRect(x: 38,
            y: 10,
            width: frameRect.width - boxRect.width - 38,
            height: 30))
    }
    func addCardName(rect: NSRect) {
        guard let card = card else { return }

        var textColor = card.textColor()
        if playerType == .CardList {
            textColor = NSColor.whiteColor()
        }

        addText(card.name, fontSize: textFontSize,
                rect: rect, textColor: textColor, font: textFont)
    }

    func addDarken() {
        if let overlay = required[.DarkOverlay] {
            addChild(overlay)
        }
    }

    private func addText(value: Int, fontSize: CGFloat,
                         rect: NSRect, textColor: NSColor, font: String,
                         strokeThickness: CGFloat = -2.0, centered: Bool = false) {
        addText("\(value)", fontSize: fontSize,
                rect: rect, textColor: textColor, font: font,
                strokeThickness: strokeThickness, centered: centered)
    }

    private func addText(value: String, fontSize: CGFloat,
                         rect: NSRect, textColor: NSColor, font: String,
                         strokeThickness: CGFloat = -2.0, centered: Bool = false) {

        if let font = NSFont(name: font, size: round(fontSize / ratioHeight)) {
            let ratioRect = ratio(rect)
            var attributes = [
                NSFontAttributeName: font,
                NSForegroundColorAttributeName: textColor,
                NSStrokeWidthAttributeName: strokeThickness,
                NSStrokeColorAttributeName: NSColor.blackColor()
            ]
            if centered {
                let paragraph = NSMutableParagraphStyle()
                paragraph.alignment = .Center
                attributes[NSParagraphStyleAttributeName] = paragraph
            }
            value.drawWithRect(ratioRect,
                               options: .TruncatesLastVisibleLine,
                               attributes: attributes)
        }
    }

    private func addChild(filename: String, rect: NSRect) {
        if let image = NSImage(contentsOfFile: filename) {
            addChild(image, rect: rect)
        }
    }

    private func addChild(image: NSImage, rect: NSRect) {
        image.drawInRect(ratio(rect))
    }

    private func addChild(themeElement: ThemeElementInfo) {
        addChild(themeElement, rect: themeElement.rect)
    }

    private func addChild(themeElement: ThemeElementInfo, rect: NSRect) {
        let fullPath = NSBundle.mainBundle().resourcePath!
            + "/Resources/Themes/Bars/\(themeDir)/\(themeElement.filename)"
        addChild(fullPath, rect: rect)
    }

    func ratio(rect: NSRect) -> NSRect {
        return NSRect(x: round(rect.origin.x / ratioWidth),
                      y: round(rect.origin.y / ratioHeight),
                      width: round(rect.size.width / ratioWidth),
                      height: round(rect.size.height / ratioHeight))
    }

    private var ratioWidth: CGFloat {
        if let playerType = playerType where playerType == .DeckManager {
            return 1.0
        }

        var ratio: CGFloat
        switch Settings.instance.cardSize {
        case .Small: ratio = CGFloat(kRowHeight / kSmallRowHeight)
        case .Medium: ratio = CGFloat(kRowHeight / kMediumRowHeight)
        default: ratio = 1.0
        }
        return ratio
    }

    private var ratioHeight: CGFloat {
        if let playerType = playerType where playerType == .DeckManager {
            return ratioWidth
        }

        let baseHeight: CGFloat
        switch Settings.instance.cardSize {
        case .Small: baseHeight = CGFloat(kSmallRowHeight)
        case .Medium: baseHeight = CGFloat(kMediumRowHeight)
        default: baseHeight = CGFloat(kRowHeight)
        }

        if baseHeight > NSHeight(self.bounds) {
            return CGFloat(kRowHeight) / NSHeight(self.bounds)
        }
        return ratioWidth
    }

    // MARK: - CardCellHover
    func setDelegate(delegate: CardCellHover) {
        self.delegate = delegate
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
        if let card = self.card {
            delegate?.hover(self, card: card)
        }
    }

    override func mouseExited(event: NSEvent) {
        if let card = self.card {
            delegate?.out(card)
        }
    }

    private func areEquals(c1: Card?, _ c2: Card?) -> Bool {
        return c1?.id == c2?.id && c1?.count == c2?.count && c1?.jousted == c2?.jousted
            && c1?.isCreated == c2?.isCreated && c1?.isStolen == c2?.isStolen
            && c1?.wasDiscarded == c2?.wasDiscarded
    }
}
