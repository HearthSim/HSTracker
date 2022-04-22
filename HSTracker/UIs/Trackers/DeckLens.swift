//
//  DeckLens.swift
//  HSTracker
//
//  Created by Francisco Moraes on 4/17/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation
import AppKit

class DeckLens: NSStackView {
    var box: NSBox
    var cards: AnimatedCardList
    var image: NSImageView
    var text: NSTextField
    
    func setLabel(label: String) {
        text.stringValue = label
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
        
        image = NSImageView(image: NSImage(named: "icon_magnifying_glass", size: NSSize(width: 17, height: 17))!)
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
            image.frame = NSRect(x: 5, y: frame.height - frameHeight + (frameHeight - 17) / 2, width: 17, height: 17)
            text.frame = NSRect(x: image.frame.maxX + 5, y: image.frame.minY, width: box.frame.width - image.frame.maxX - 5, height: 17)
            cards.frame = NSRect(x: 0, y: 5, width: frame.width, height: frame.height - frameHeight - 5)
            cards.updateFrames()
        } else {
            frame = NSRect.zero
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
