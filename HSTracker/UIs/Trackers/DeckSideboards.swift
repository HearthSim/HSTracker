//
//  DeckLens.swift
//  HSTracker
//
//  Created by Francisco Moraes on 3/31/24.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation
import AppKit

class DeckSideboards: NSStackView {
    var etcContainer: NSBox
    var cards: AnimatedCardList
    var text: NSTextField
    
    func setLabel(label: String) {
        text.stringValue = label
    }
    
    override init(frame: NSRect) {
        etcContainer = NSBox()
        etcContainer.boxType = .custom
        etcContainer.borderType = .noBorder
        etcContainer.titlePosition = .noTitle
        etcContainer.borderWidth = 0
        etcContainer.contentViewMargins = NSSize.zero
        etcContainer.fillColor = NSColor.fromHexString(hex: "23272A")!
        etcContainer.borderColor = NSColor.fromHexString(hex: "141617")!
                
        text = NSTextField(labelWithString: String.localizedString("DeckSideboard_Label_ETCBand", comment: ""))
        text.textColor = NSColor.white
        etcContainer.addSubview(text)
        
        cards = AnimatedCardList()
        etcContainer.addSubview(cards)
                        
        super.init(frame: frame)

        orientation = .vertical
        spacing = 0
        
        addSubview(etcContainer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateFrames(frameHeight: CGFloat) {
        if cards.count > 0 {
            etcContainer.frame = NSRect(x: 0, y: 0, width: frame.width, height: frame.height)
            text.frame = NSRect(x: 5, y: frame.height - frameHeight + (frameHeight - 17) / 2, width: etcContainer.frame.width - 5, height: 17)
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
    
    func update(sideboards: [Sideboard], reset: Bool) {
        if sideboards.count == 0 || sideboards.all({ s in s.cards.count == 0 }) {
            if cards.count > 0 {
                cards.update(cards: [], reset: reset)
            }
            isHidden = true
            return
        }
        if let etcSideboard = sideboards.first(where: { s in s.ownerCardId == CardIds.Collectible.Neutral.ETCBandManager }) {
            if self.cards.update(cards: etcSideboard.cards, reset: reset) {
                AppDelegate.instance().coreManager.game.updatePlayerTracker(reset: false)
            }
            etcContainer.isHidden = etcSideboard.cards.count == 0
        } else {
            etcContainer.isHidden = true
        }
        isHidden = etcContainer.isHidden
    }
}
