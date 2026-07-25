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
    
    var kingOfTheUnderbellyContainer: NSBox
    var kingOfTheUnderbellyCardList: AnimatedCardList
    
    var text: NSTextField
    var kingOfTheUnderbellyText: NSTextField
    
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

        kingOfTheUnderbellyContainer = NSBox()
        kingOfTheUnderbellyContainer.boxType = .custom
        kingOfTheUnderbellyContainer.borderType = .noBorder
        kingOfTheUnderbellyContainer.titlePosition = .noTitle
        kingOfTheUnderbellyContainer.borderWidth = 0
        kingOfTheUnderbellyContainer.contentViewMargins = NSSize.zero
        kingOfTheUnderbellyContainer.fillColor = NSColor.fromHexString(hex: "23272A")!
        kingOfTheUnderbellyContainer.borderColor = NSColor.fromHexString(hex: "141617")!
                
        kingOfTheUnderbellyText = NSTextField(labelWithString: Cards.by(cardId: CardIds.Collectible.Hunter.KingOfTheUnderbelly)?.name ?? "King of the Underbelly")
        kingOfTheUnderbellyText.textColor = NSColor.white
        kingOfTheUnderbellyContainer.addSubview(kingOfTheUnderbellyText)
        
        kingOfTheUnderbellyCardList = AnimatedCardList()
        kingOfTheUnderbellyContainer.addSubview(kingOfTheUnderbellyCardList)

        super.init(frame: frame)

        orientation = .vertical
        spacing = 0
        
        addSubview(etcContainer)
        addSubview(kingOfTheUnderbellyContainer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateFrames(frameHeight: CGFloat, cardHeight: CGFloat) {
        if cards.count > 0 || kingOfTheUnderbellyCardList.count > 0 {
            var y = 0.0
            if kingOfTheUnderbellyCardList.count > 0 {
                kingOfTheUnderbellyContainer.frame = NSRect(x: 0, y: y, width: frame.width, height: frameHeight + CGFloat(kingOfTheUnderbellyCardList.count) * cardHeight)
                let kotuFrame = kingOfTheUnderbellyContainer.frame
                kingOfTheUnderbellyText.frame = NSRect(x: 5, y: kotuFrame.height - frameHeight + (frameHeight - 17) / 2, width: kotuFrame.width - 5, height: 17)
                kingOfTheUnderbellyCardList.frame = NSRect(x: 0, y: 5, width: frame.width, height: kingOfTheUnderbellyContainer.frame.height - frameHeight - 5)
                kingOfTheUnderbellyCardList.updateFrames()
                y += kingOfTheUnderbellyContainer.frame.height
            }
            if cards.count > 0 {
                etcContainer.frame = NSRect(x: 0, y: y, width: frame.width, height: frameHeight + CGFloat(cards.count) * cardHeight)
                let etcFrame = etcContainer.frame
                text.frame = NSRect(x: 5, y: etcFrame.height - frameHeight + (frameHeight - 17) / 2, width: etcFrame.width - 5, height: 17)
                cards.frame = NSRect(x: 0, y: 5, width: frame.width, height: etcFrame.height - frameHeight - 5)
                cards.updateFrames()
                y += etcContainer.frame.height
            }
        } else {
            frame = NSRect.zero
            cards.updateFrames()
            kingOfTheUnderbellyCardList.updateFrames()
        }
    }
    
    var count: Int {
        return cards.count + kingOfTheUnderbellyCardList.count
    }
    
    var sideboardCount: Int {
        return (cards.count > 0 ? 1 : 0) + (kingOfTheUnderbellyCardList.count > 0 ? 1 : 0)
    }
    
    func setPlayerType(playerType: PlayerType) {
        cards.playerType = playerType
        kingOfTheUnderbellyCardList.playerType = playerType
    }
    
    func setDelegate(delegate: CardCellHover) {
        cards.delegate = delegate
        kingOfTheUnderbellyCardList.delegate = delegate
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
        
        if let kingOfTheUnderbellySideboard = sideboards.first(where: { s in s.ownerCardId == CardIds.Collectible.Hunter.KingOfTheUnderbelly }) {
            if kingOfTheUnderbellyCardList.update(cards: kingOfTheUnderbellySideboard.cards, reset: reset) {
                AppDelegate.instance().coreManager.game.updatePlayerTracker(reset: false)
            }
            kingOfTheUnderbellyContainer.isHidden = kingOfTheUnderbellySideboard.cards.count == 0
        } else {
            kingOfTheUnderbellyContainer.isHidden = true
        }

        isHidden = etcContainer.isHidden && kingOfTheUnderbellyContainer.isHidden
    }
}
