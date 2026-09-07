//
//  DeckLens.swift
//  HSTracker
//
//  Created by Francisco Moraes on 4/17/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation
import AppKit

/// Ports HDT's `DeckLensIcon`.
enum DeckLensIcon {
    case lens, arenasmith
}

class DeckLens: NSStackView {
    /// `HSReplayNetPremiumGold` from HDT's App.xaml.
    static let premiumGold = NSColor.fromHexString(hex: "FFB00D")!

    var box: NSBox
    var cards: AnimatedCardList
    var image: NSImageView
    var text: NSTextField

    /// Which glyph sits next to the label. HDT keeps both in the control and
    /// collapses one; here the image view just swaps its content, along with the
    /// size the two are drawn at in DeckLens.xaml (17x17 and 19x12).
    var icon: DeckLensIcon = .lens {
        didSet {
            updateIcon()
            updateColors()
        }
    }

    /// Colours the label and the icon gold instead of white, matching HDT's
    /// `UpdateColors`.
    var isPremium = false {
        didSet { updateColors() }
    }

    func setLabel(label: String) {
        text.stringValue = label
    }

    private var iconSize: NSSize {
        switch icon {
        case .lens: return NSSize(width: 17, height: 17)
        case .arenasmith: return NSSize(width: 19, height: 12)
        }
    }

    private func updateIcon() {
        switch icon {
        case .lens:
            #if HSTTEST
            image.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: nil)
            #else
            image.image = NSImage(named: "icon_magnifying_glass", size: iconSize)
            #endif
        case .arenasmith:
            // The asset is a single white path, so a template copy is what lets
            // contentTintColor stand in for HDT's LogoBrush. Copied rather than
            // flagged in place: NSImage(named:) hands out a shared instance, and
            // the pre-draft panel draws the same asset untinted.
            let logo = (NSImage(named: "arenasmith-logo")?.copy() as? NSImage)
            logo?.isTemplate = true
            // The mark is 74x42 and DeckLens.xaml draws it in a 19x12 box; WPF's
            // Image stretches Uniform, so fit rather than distort.
            image.imageScaling = .scaleProportionallyUpOrDown
            image.image = logo
        }
    }

    private func updateColors() {
        let color = isPremium ? DeckLens.premiumGold : NSColor.white
        text.textColor = color
        image.contentTintColor = color
    }
    
    override init(frame: NSRect) {
        box = NSBox()
        box.boxType = .custom
        box.borderType = .noBorder
        box.titlePosition = .noTitle
        box.borderWidth = 0
        box.contentViewMargins = NSSize.zero
        box.fillColor = NSColor.fromHexString(hex: "23272A")!
        box.borderColor = NSColor.fromHexString(hex: "141617")!
        
        #if HSTTEST
        image = NSImageView(image: NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: nil)!)
        #else
        image = NSImageView(image: NSImage(named: "icon_magnifying_glass", size: NSSize(width: 17, height: 17))!)
        #endif
        box.addSubview(image)
        
        text = NSTextField(labelWithString: "")
        text.textColor = NSColor.white
        box.addSubview(text)
                        
        cards = AnimatedCardList()
        box.addSubview(cards)

        super.init(frame: frame)

        orientation = .vertical
        spacing = 0
        
        addSubview(box)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateFrames(frameHeight: CGFloat) {
        if cards.count > 0 {
            box.frame = NSRect(x: 0, y: 0, width: frame.width, height: frame.height)
            let iconSize = self.iconSize
            image.frame = NSRect(x: 5, y: frame.height - frameHeight + (frameHeight - iconSize.height) / 2,
                                 width: iconSize.width, height: iconSize.height)
            text.frame = NSRect(x: image.frame.maxX + 5, y: frame.height - frameHeight + (frameHeight - 17) / 2,
                                width: box.frame.width - image.frame.maxX - 5, height: 17)
            cards.frame = NSRect(x: 0, y: 5, width: frame.width, height: frame.height - frameHeight - 5)
            cards.updateFrames()
        } else {
            frame = NSRect.zero
            cards.updateFrames()
        }
    }
    
    var count: Int {
        return cards.count
    }
    
    func setPlayerType(playerType: PlayerType) {
        cards.playerType = playerType
    }
    
    func setDelegate(delegate: CardCellHover) {
        cards.delegate = delegate
    }
    
    func update(cards: [Card], reset: Bool) {
        if self.cards.update(cards: cards, reset: reset) {
            AppDelegate.instance().coreManager.game.updatePlayerTracker(reset: false)
        }
    }
}
