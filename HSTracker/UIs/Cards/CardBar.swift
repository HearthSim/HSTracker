//
//  CardBar.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 31/05/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import TextAttributes

protocol CardCellHover: AnyObject {
    func hover(cell: CardBar, card: Card)
    func out(card: Card)
}

protocol CardBarTheme {
    var card: Card? {get set}
    var playerType: PlayerType? {get set}
    var playerName: String? {get set}
    var playerRank: Int? {get set}
    var isArena: Bool? {get set}
}

class CardBar: NSView, CardBarTheme {
    private lazy var trackingArea: NSTrackingArea = {
        return NSTrackingArea(rect: NSRect.zero,
                              options: [.inVisibleRect, .activeAlways, .mouseEnteredAndExited],
                              owner: self,
                              userInfo: nil)
    }()
    weak private var delegate: CardCellHover?

    private var flashLayer: CALayer?
    private var cardLayer: CALayer?

    class func factory() -> CardBar {
        switch Settings.theme {
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

    private var cardTile: NSImage?
    private var oldCard: Card?
    var card: Card? {
        didSet {
            oldCard = oldValue
            if oldCard?.id != card?.id {
                cardTile = nil
            }
        }
    }
    var playerType: PlayerType?
    var playerName: String?
    var playerRank: Int?
    var isArena: Bool?
    var playerRace: Race?
    var backgroundImage: NSImage?
    var isBattlegrounds: Bool = false

    var hasAllRequired: Bool {
        guard let rp = Bundle.main.resourcePath else {
            return false
        }
        let path = "\(rp)/Resources/Themes/Bars/\(themeDir)/"
        let manager = FileManager.default
        return required.map { $0.1 } .all {
            manager.fileExists(atPath: "\(path)\($0.filename)")
        }
    }

    private var hasAllOptionalFrames: Bool {
        guard let rp = Bundle.main.resourcePath else {
            return false
        }
        let path = "\(rp)/Resources/Themes/Bars/\(themeDir)/"
        let manager = FileManager.default
        return optionalFrame.map { $0.1 } .all {
            manager.fileExists(atPath: "\(path)\($0.filename)")
        }
    }

    private var hasAllOptionalGems: Bool {
        guard let rp = Bundle.main.resourcePath else {
            return false
        }
        let path = "\(rp)/Resources/Themes/Bars/\(themeDir)/"
        let manager = FileManager.default
        return optionalGems.map { $0.1 } .all {
            manager.fileExists(atPath: "\(path)\($0.filename)")
        }
    }

    private var hasAllOptionalCountBoxes: Bool {
        guard let rp = Bundle.main.resourcePath else {
            return false
        }
        let path = "\(rp)/Resources/Themes/Bars/\(themeDir)/"
        let manager = FileManager.default
        return optionalCountBoxes.map { $0.1 } .all {
            manager.fileExists(atPath: "\(path)\($0.filename)")
        }
    }

    var fadeOffset: CGFloat = -23
    var imageOffset: CGFloat = -23
    var createdIconOffset: CGFloat = -23

    var countFontSize: CGFloat = 17
    var mulliganWinRateFontSize: CGFloat = 15
    var textFontSize: CGFloat = 15
    var costFontSize: CGFloat = 20
    var flashColor: NSColor {
        return NSColor.white
    }

    let frameRect = NSRect(x: 0, y: 0, width: 217, height: 34)
    let gemRect = NSRect(x: 0, y: 0, width: 34, height: 34)
    let boxRect = NSRect(x: 183, y: 0, width: 34, height: 34)
    let mulliganWinrateBoxRect = NSRect(x: 136, y: 4, width: 54, height: 26)
    let imageRect = NSRect(x: 83, y: 0, width: 134, height: 34)
    let imageRectBG = NSRect(x: 0, y: 0, width: 217, height: 34)
    let countTextRect = NSRect(x: 198, y: 9, width: CGFloat.greatestFiniteMagnitude, height: 34)
    let costTextRect = NSRect(x: 0, y: 9, width: 34, height: 34)
    let arenaHelperRect = NSRect(x: 17, y: 0, width: 34, height: 34)
    let tag1 = NSRect(x: 183, y: 0, width: 34, height: 34)
    let tag2 = NSRect(x: 149, y: 0, width: 34, height: 34)

    var countTextColor: NSColor {
        return NSColor( red: 0.9221, green: 0.7215, blue: 0.2226, alpha: 1.0 )
    }
    var numbersFont: String {
        return "ChunkFive"
    }
    var textFont: String {
        if Settings.isSimplifiedChinese {
            return "AR LisuGB Medium"
        } else if Settings.isAsianLanguage {
            return "NanumGothic"
        } else if Settings.isCyrillicLanguage {
            return "BenguiatBold"
        } else {
            return "ChunkFive"
        }
    }

    var required: [ThemeElement: ThemeElementInfo] {
        return [
            .defaultFrame: ThemeElementInfo(filename: "frame.png", rect: frameRect),
            .defaultGem: ThemeElementInfo(filename: "gem.png", rect: gemRect),
            .defaultCountBox: ThemeElementInfo(filename: "countbox.png", rect: boxRect),
            .darkOverlay: ThemeElementInfo(filename: "dark.png", rect: frameRect),
            .fadeOverlay: ThemeElementInfo(filename: "fade.png", rect: frameRect),
            .createdIcon: ThemeElementInfo(filename: "icon_created.png", rect: boxRect),
            .badAsMultipleIcon: ThemeElementInfo(filename: "icon_bad_multiple.png",
                                                 rect: arenaHelperRect),
            .legendaryIcon: ThemeElementInfo(filename: "icon_legendary.png", rect: boxRect),
            .flashFrame: ThemeElementInfo(filename: "frame_mask.png", rect: frameRect),
            .defaultKeepRateBox: ThemeElementInfo(filename: "keeprate_box.png", rect: mulliganWinrateBoxRect),
            .defaultKeepRateActiveBox: ThemeElementInfo(filename: "keeprate_active_box.png", rect: mulliganWinrateBoxRect)
        ]
    }
    var optionalFrame: [ThemeElement: ThemeElementInfo] {
        return [
            .commonFrame: ThemeElementInfo(filename: "frame_common.png", rect: frameRect),
            .rareFrame: ThemeElementInfo(filename: "frame_rare.png", rect: frameRect),
            .epicFrame: ThemeElementInfo(filename: "frame_epic.png", rect: frameRect),
            .legendaryFrame: ThemeElementInfo(filename: "frame_legendary.png", rect: frameRect)
        ]
    }

    var optionalGems: [ThemeElement: ThemeElementInfo] {
        return [
            .commonGem: ThemeElementInfo(filename: "gem_common.png", rect: gemRect),
            .rareGem: ThemeElementInfo(filename: "gem_rare.png", rect: gemRect),
            .epicGem: ThemeElementInfo(filename: "gem_epic.png", rect: gemRect),
            .legendaryGem: ThemeElementInfo(filename: "gem_legendary.png", rect: gemRect)
        ]
    }

    var optionalCountBoxes: [ThemeElement: ThemeElementInfo] {
        return [
            .commonCountBox: ThemeElementInfo(filename: "countbox_common.png", rect: boxRect),
            .rareCountBox: ThemeElementInfo(filename: "countbox_rare.png", rect: boxRect),
            .epicCountBox: ThemeElementInfo(filename: "countbox_epic.png", rect: boxRect),
            .legendaryCountBox: ThemeElementInfo(filename: "countbox_legendary.png", rect: boxRect)
        ]
    }

    init() {
        super.init(frame: NSRect.zero)
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

        layer?.backgroundColor = NSColor.clear.cgColor
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
        if highlight && Settings.flashOnDraw {
            if let themeElement = required[.flashFrame] {
                guard let rp = Bundle.main.resourcePath else {
                    return
                }
                let fullPath = "\(rp)/Resources/Themes/Bars/\(themeDir)/\(themeElement.filename)"
                if let image = NSImage(contentsOfFile: fullPath),
                    FileManager.default.fileExists(atPath: fullPath) {
                    let flashingLayer = CALayer()
                    flashingLayer.frame = ratio(frameRect)
                    flashingLayer.backgroundColor = flashColor.cgColor

                    let maskLayer = CALayer()
                    maskLayer.frame = ratio(frameRect)
                    maskLayer.contents = image
                    flashingLayer.mask = maskLayer

                    flashLayer?.addSublayer(flashingLayer)
                    let fade = CABasicAnimation(keyPath: "opacity")
                    fade.fromValue = 0.7
                    fade.toValue = 0.0
                    fade.duration = 0.5
                    fade.isRemovedOnCompletion = false
                    fade.fillMode = CAMediaTimingFillMode.both
                    flashingLayer.add(fade, forKey: "alpha")
                }
            }
        }
    }

    // MARK: - animation
    func fadeIn(highlight: Bool) {
        if highlight {
            self.alphaValue = 0.3
            NSAnimationContext.runAnimationGroup({ (context) in
                context.duration = 0.5
                self.animator().alphaValue = 1.0
                }, completionHandler: nil)
        }
    }

    func fadeOut(highlight: Bool) {
        if highlight {
            NSAnimationContext.runAnimationGroup({ (context) in
                context.duration = 0.5
                self.animator().alphaValue = 0.3
                }, completionHandler: nil)
        }
    }

    // MARK: - drawing
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard hasAllRequired else { return }

        if let card = card, areEquals(card, oldCard) && playerType != .hero { return }

        cardLayer?.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        if let img = backgroundImage {
            add(image: img, rect: isBattlegrounds ? imageRectBG : imageRect)
        }
        
        addCardImage()
        addFadeOverlay()

        if let card = card {
            if (abs(card.count) > 1 && playerType != .editDeck) || card.rarity == .legendary {
                addCountBox()
                addCountText()
            }
            if card.isCreated {
                addCreatedIcon()
            }
            if (abs(card.count) <= 1 || playerType == .editDeck) && card.rarity == .legendary {
                if !isBattlegrounds {
                    addLegendaryIcon()
                }
            }
            if isBattlegrounds {
                let hasBattleCry = card.mechanics.contains("BATTLECRY")
                let hasDeathrattle = card.mechanics.contains("DEATHRATTLE")
                if hasBattleCry {
                    addBattlecryTag(position: hasDeathrattle ? 2 : 1)
                }
                if hasDeathrattle {
                    addDeathrattleTag()
                }
            }
        }
        if (isBattlegrounds && card != nil) || !isBattlegrounds {
            addFrame()
        }

        if card != nil {
            addGem()
            addCost()
        }
        addCardName()
        if let card = card, card.isBadAsMultiple {
            addBadAsMultipleIcon()
        }
        if let card = card, playerType != .hero {
            if let isArena = isArena,
                playerType == .editDeck && !isArena
                    && (card.count >= 2 || (card.count == 1 && card.rarity == .legendary)) {
                addDarken()
            } else if (card.count <= 0 || card.jousted)
                && playerType != .cardList && playerType != .editDeck {
                addDarken()
            }
        }
        if card?.cardWinRates != nil {
            addMulliganWinRate()
            addMulliganWinRateText()
        }
    }

    func addCardImage() {
        addCardImage(rect: imageRect)
    }
    func addCardImage(rect: NSRect, offsetByCountBox: Bool = false) {
        guard let card = card else { return }
        let rarity = card.rarity
        var count = card.count
        if count == 0 { count = 1 }
        var offset = offsetByCountBox
        var r = rect
        if isBattlegrounds {
            offset = false
            r = imageRectBG
        }

        if let image = cardTile {
            if offset && abs(count) > 1 && playerType != .editDeck || rarity == .legendary {
                add(image: image, rect: r.offsetBy(dx: imageOffset, dy: 0))
            } else {
                add(image: image, rect: r)
            }

            return
        } else if let image = ImageUtils.cachedTile(cardId: card.id) {
            if offset && abs(count) > 1 && playerType != .editDeck || rarity == .legendary {
                add(image: image, rect: r.offsetBy(dx: imageOffset, dy: 0))
            } else {
                add(image: image, rect: r)
            }

            return
        }

        ImageUtils.tile(for: card.id, completion: { [weak self] in
            guard let image = $0 else {
                logger.warning("No image for \(card)")
                return
            }

            self?.cardTile = image
            DispatchQueue.main.async { [weak self] in
                self?.needsDisplay = true
            }
        })
    }

    func addFadeOverlay() {
        if let rect = required[.fadeOverlay]?.rect {
            addFadeOverlay(rect: rect)
        }
    }
    func addFadeOverlay(rect: NSRect, offsetByCountBox: Bool = false) {
        var rarity: Rarity = .free
        var count = 1

        if let card = card {
            count = card.count
            rarity = card.rarity
        } else if isBattlegrounds {
            return
        }

        if let fadeOverlay = required[.fadeOverlay] {
            if offsetByCountBox && (abs(count) > 1 || rarity == .legendary) {
                add(themeElement: fadeOverlay, rect: rect.offsetBy(dx: fadeOffset, dy: 0))
            } else {
                add(themeElement: fadeOverlay, rect: rect)
            }
        }
    }

    func addCountBox() {
        guard let card = card else { return }

        var countBox = required[.defaultCountBox]
        if Settings.showRarityColors && hasAllOptionalCountBoxes {
            switch card.rarity {
            case .rare:
                countBox = optionalCountBoxes[.rareCountBox]
            case .epic:
                countBox = optionalCountBoxes[.epicCountBox]
            case .legendary:
                countBox = optionalCountBoxes[.legendaryCountBox]
            default:
                countBox = optionalCountBoxes[.commonCountBox]
            }
        }

        if let countBox = countBox {
            add(themeElement: countBox)
        }
    }

    func addCountText() {
        addCountText(countTextRect)
    }
    func addCountText(_ rect: NSRect) {
        guard let card = card else { return }

        let  count = abs(card.count)
        guard count > 1 else { return }

        add(text: min(count, 9), fontSize: countFontSize,
                rect: rect, textColor: countTextColor, font: numbersFont)
        if count > 9 {
            add(text: "+", fontSize: 13,
                    rect: NSRect(x: rect.origin.x + 5, y: 3,
                        width: CGFloat.greatestFiniteMagnitude,
                        height: CGFloat.greatestFiniteMagnitude),
                    textColor: countTextColor, font: textFont)
        }
    }

    func addBadAsMultipleIcon() {
        if let rect = required[.badAsMultipleIcon]?.rect {
            addBadAsMultipleIcon(rect: rect)
        }
    }
    func addBadAsMultipleIcon(rect: NSRect) {
        if let badAsMultipleIcon = required[.badAsMultipleIcon] {
            add(themeElement: badAsMultipleIcon, rect: rect)
        }
    }
    
    func addMulliganWinRate() {
        if let card, let mulliganWinRateBox = required[card.isMulliganOption ? .defaultKeepRateActiveBox : .defaultKeepRateBox] {
            add(themeElement: mulliganWinRateBox, rect: mulliganWinrateBoxRect)
        }
    }
    
    func addMulliganWinRateText() {
        if let card {
            var color = Color.white
            var text = ""
            if let winrate = card.cardWinRates?.mulliganWinRate {
                let baseWinrate = card.cardWinRates?.baseWinrate
                let delta = (winrate - (baseWinrate ?? 50.0))
                let tmpcolor = Helper.getColorString(delta: delta, intensity: 75)
                color = NSColor.fromHexString(hex: tmpcolor) ?? Color.white
                text = String(format: "%.1f%%", winrate)
            }
            let textRect = NSRect(x: mulliganWinrateBoxRect.minX, y: mulliganWinrateBoxRect.minY + 8, width: mulliganWinrateBoxRect.width, height: mulliganWinrateBoxRect.height - 6)
            add(text: text, fontSize: mulliganWinRateFontSize, rect: textRect, textColor: color, font: textFont, strokeThickness: -2.0, centered: true)
        }
    }

    func addCreatedIcon() {
        if let rect = required[.createdIcon]?.rect {
            addCreatedIcon(rect: rect)
        }
    }
    func addCreatedIcon(rect: NSRect) {
        guard let card = card else { return }

        if let createdIcon = required[.createdIcon] {
            if abs(card.count) > 1 || card.rarity == .legendary {
                add(themeElement: createdIcon, rect: rect.offsetBy(dx: createdIconOffset, dy: 0))
            } else {
                add(themeElement: createdIcon, rect: rect)
            }
        }
    }

    func addLegendaryIcon() {
        if let rect = required[.legendaryIcon]?.rect {
            addLegendaryIcon(rect: rect)
        }
    }
    func addLegendaryIcon(rect: NSRect) {
        if let icon = required[.legendaryIcon] {
            add(themeElement: icon, rect: rect)
        }
    }
    
    func addBattlecryTag(position: Int) {
        let rect = position == 1 ? tag1 : tag2
        if #available(macOS 11.0, *) {
            var image = NSImage(systemSymbolName: "b.circle.fill", accessibilityDescription: nil)!
            if #available(macOS 12.0, *) {
                let config = NSImage.SymbolConfiguration(paletteColors: [ .white, .black ])
                image = image.withSymbolConfiguration(config)!
            }
            add(image: image, rect: rect)
        }
    }
    func addDeathrattleTag() {
        if #available(macOS 11.0, *) {
            var image = NSImage(systemSymbolName: "d.circle.fill", accessibilityDescription: nil)!
            if #available(macOS 12.0, *) {
                let config = NSImage.SymbolConfiguration(paletteColors: [ .white, .black ])
                image = image.withSymbolConfiguration(config)!
            }
            add(image: image, rect: tag1)
        }
    }

    func addFrame() {
        var rarity: Rarity = .common
        if let card = card {
            rarity = card.rarity
        }

        var frame = required[.defaultFrame]
        if Settings.showRarityColors && hasAllOptionalFrames {
            switch rarity {
            case .rare:
                frame = optionalFrame[.rareFrame]
            case .epic:
                frame = optionalFrame[.epicFrame]
            case .legendary:
                frame = optionalFrame[.legendaryFrame]
            default:
                frame = optionalFrame[.commonFrame]
            }
        }

        if let frame = frame {
            add(themeElement: frame)
        }
    }

    func addGem() {
        guard let card = card else { return }
        if Cards.isHero(cardId: card.id) && !Cards.isPlayableHero(cardId: card.id) { return }
        if card.cost < 0 { return }

        var gem = required[.defaultGem]
        if Settings.showRarityColors && hasAllOptionalGems {
            switch card.rarity {
            case .rare:
                gem = optionalGems[.rareGem]
            case .epic:
                gem = optionalGems[.epicGem]
            case .legendary:
                gem = optionalGems[.legendaryGem]
            default:
                gem = optionalGems[.commonGem]
            }
        }

        if let gem = gem {
            add(themeElement: gem)
        }
    }

    func addCost() {
        addCost(rect: costTextRect)
    }
    func addCost(rect: NSRect) {
        guard let card = card else { return }

        var cost = card.cost
        
        if cost < 0 {
            return
        }

        var textColor = card.textColor()
        if playerType == .cardList || playerType == .editDeck {
            textColor = .white
        }
     
        if Cards.isHero(cardId: card.id) && !Cards.isPlayableHero(cardId: card.id) {
            if let rank = playerRank, rank > 0 {
                textColor = .white
                cost = rank
            } else {
                return
            }
        }

        add(text: cost, fontSize: costFontSize, rect: rect,
                textColor: textColor, font: numbersFont,
                strokeThickness: -1.0, centered: true)
    }

    func addCardName() {
        let keepWidth = card?.cardWinRates != nil ? mulliganWinrateBoxRect.width : 0
        var width = frameRect.width - keepWidth - (isBattlegrounds ? 14 : 38)
        if let card = card {
            if abs(card.count) > 0 || card.rarity == .legendary {
                width -= boxRect.width
            }
            if card.isCreated {
                // createdIconOffset is negative, add abs for readability
                width -= abs(createdIconOffset)
            }
        }
        addCardName(rect: NSRect(x: isBattlegrounds ? 14 : 38,
            y: 10,
            width: width,
            height: 30))
    }
    
    func fitFontForSize(_ constrainedSize: CGSize,
                        str: String,
                        fontName: String,
                        maxFontSize: CGFloat = 15,
                        minFontSize: CGFloat = 5,
                        accuracy: CGFloat = 1) -> CGFloat {
        assert(maxFontSize > minFontSize)

        var minFontSize = minFontSize
        var maxFontSize = maxFontSize
        var fittingSize = constrainedSize

        while maxFontSize - minFontSize > accuracy {
            let midFontSize: CGFloat = ((minFontSize + maxFontSize) / 2)
            if let font = NSFont(name: fontName, size: round(midFontSize / ratioHeight)) {
                let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font,
                                  NSAttributedString.Key.strokeWidth: -2.0]
                let options: NSString.DrawingOptions = [ .usesFontLeading, .usesDeviceMetrics]
                let size = CGSize(width: constrainedSize.width, height: constrainedSize.height)
                let attributedString = NSAttributedString(string: str, attributes: attributes)
                let context = NSStringDrawingContext()
                context.minimumScaleFactor = 0.01
                fittingSize = attributedString.boundingRect(with: size, options: options, context: context).size

                if fittingSize.height <= constrainedSize.height && fittingSize.width <= constrainedSize.width {
                    minFontSize = midFontSize
                } else {
                    maxFontSize = midFontSize
                }
            }
        }

        return min(minFontSize, maxFontSize)
    }
    
    func addCardName(rect: NSRect) {
        var name: String?
        var textColor: NSColor = .white

        if let playerName = playerName {
            name = playerName
        } else if let card = card {
            name = card.name
            textColor = card.textColor()
        }

        if playerType == .cardList || playerType == .editDeck {
            textColor = NSColor.white
        }

        if let name = name {
            let fontSize = fitFontForSize(ratio(rect).size, str: name, fontName: textFont, maxFontSize: 15.0, minFontSize: 1.0)
            add(text: name, fontSize: fontSize, rect: rect, textColor: textColor, font: textFont)
        }
    }

    func addDarken() {
        if let overlay = required[.darkOverlay] {
            add(themeElement: overlay)
        }
    }

    private func add(text value: Int, fontSize: CGFloat,
                     rect: NSRect, textColor: NSColor, font: String,
                     strokeThickness: CGFloat = -2.0, centered: Bool = false) {
        add(text: "\(value)", fontSize: fontSize,
            rect: rect, textColor: textColor, font: font,
            strokeThickness: strokeThickness, centered: centered)
    }

    private func add(text value: String, fontSize: CGFloat,
                     rect: NSRect, textColor: NSColor, font: String,
                     strokeThickness: CGFloat = -2.0, centered: Bool = false) {

        if let font = NSFont(name: font, size: fontSize / ratioHeight) {
            let ratioRect = ratio(rect)
            var attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor,
                .strokeWidth: strokeThickness,
                .strokeColor: NSColor.black
            ]
            if centered {
                let paragraph = NSMutableParagraphStyle()
                paragraph.alignment = .center
                attributes[.paragraphStyle] = paragraph
            }
            let context = NSStringDrawingContext()
            context.minimumScaleFactor = 0.001
            value.draw(with: ratioRect,
                       options: [.usesFontLeading],
                       attributes: attributes,
                       context: context)
        }
    }

    private func add(filename: String, rect: NSRect) {
        if let image = NSImage(contentsOfFile: filename) {
            add(image: image, rect: rect)
        }
    }

    private func add(image: NSImage, rect: NSRect) {
        image.draw(in: ratio(rect))
    }

    private func add(themeElement: ThemeElementInfo) {
        add(themeElement: themeElement, rect: themeElement.rect)
    }

    private func add(themeElement: ThemeElementInfo, rect: NSRect) {
        guard let rp = Bundle.main.resourcePath else {
            return
        }
        let fullPath = "\(rp)/Resources/Themes/Bars/\(themeDir)/\(themeElement.filename)"
        add(filename: fullPath, rect: rect)
    }

    func ratio(_ rect: NSRect) -> NSRect {
        return NSRect(x: round(rect.origin.x / ratioWidth),
                      y: round(rect.origin.y / ratioHeight),
                      width: round(rect.size.width / ratioWidth),
                      height: round(rect.size.height / ratioHeight))
    }

    private var ratioWidth: CGFloat {
        if let playerType = playerType, !isBattlegrounds && (playerType == .deckManager || playerType == .editDeck) {
            return 1.0
        }

        var ratio: CGFloat
        switch Settings.cardSize {
        case .tiny: ratio = CGFloat(kRowHeight / kTinyRowHeight)
        case .small: ratio = CGFloat(kRowHeight / kSmallRowHeight)
        case .medium: ratio = CGFloat(kRowHeight / kMediumRowHeight)
        case .huge: ratio = CGFloat(kRowHeight / kHighRowHeight)
        case .big: ratio = 1.0
        }
        return ratio
    }

    private var ratioHeight: CGFloat {
        if let playerType = playerType, !isBattlegrounds && (playerType == .deckManager || playerType == .editDeck) {
            return ratioWidth
        }

        let baseHeight: CGFloat
        switch Settings.cardSize {
        case .tiny: baseHeight = CGFloat(kTinyRowHeight)
        case .small: baseHeight = CGFloat(kSmallRowHeight)
        case .medium: baseHeight = CGFloat(kMediumRowHeight)
        case .huge: baseHeight = CGFloat(kHighRowFrameWidth)
        case .big: baseHeight = CGFloat(kRowHeight)
        }

        if baseHeight > self.bounds.height {
            return CGFloat(kRowHeight) / self.bounds.height
        }
        return ratioWidth
    }

    // MARK: - CardCellHover
    func setDelegate(_ delegate: CardCellHover) {
        self.delegate = delegate
    }

    // MARK: - mouse hover
    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if !self.trackingAreas.contains(trackingArea) {
            self.addTrackingArea(trackingArea)
        }
    }

    override func mouseEntered(with event: NSEvent) {
        if let card = self.card {
            delegate?.hover(cell: self, card: card)
        }
    }

    override func mouseExited(with event: NSEvent) {
        if let card = self.card {
            delegate?.out(card: card)
        }
    }

    private func areEquals(_ c1: Card?, _ c2: Card?) -> Bool {
        return c1?.id == c2?.id && c1?.count == c2?.count && c1?.jousted == c2?.jousted
            && c1?.isCreated == c2?.isCreated && c1?.isStolen == c2?.isStolen
            && c1?.wasDiscarded == c2?.wasDiscarded
    }
}

extension NSImage {
    convenience init(color: NSColor, size: NSSize) {
        self.init(size: size)
        lockFocus()
        color.drawSwatch(in: NSRect(origin: .zero, size: size))
        unlockFocus()
    }
}

extension CardBar {
    override var description: String {
        return "[\(card?.id ?? ""):\(card?.count ?? 0)]"
    }
}

