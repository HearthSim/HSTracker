//
//  BattlegroundsOverlayView.swift
//  HSTracker
//
//  Created by Martin BONNIN on 30/11/2019.
//  Copyright © 2019 HearthSim LLC. All rights reserved.
//

import Foundation
import kotlin_hslog

class BattlegroundsDetailsView: NSView {
    var board: BattlegroundsBoard?
    var cache: [(String, NSImage)] = []

    init() {
        super.init(frame: NSRect.zero)
        logger.debug("BattlegroundsDetailsView created")
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let backgroundColor: NSColor = NSColor.clear
        //let backgroundColor = NSColor.init(red: 0x48/255.0, green: 0x7E/255.0, blue: 0xAA/255.0, alpha: 0.3)
        
        backgroundColor.set()
        dirtyRect.fill()
        
        if let board = self.board {
            drawBoard(board: board)
        }
    }
    
    func drawBoard(board: BattlegroundsBoard) {
        drawTurn(turns: (board.currentTurn - board.turn)/2)
        
        var i = 0
        let rect = NSRect(x: 0, y: 0, width: bounds.width/7, height: bounds.height - CGFloat(30)).insetBy(dx: 4, dy: 4)
        for minion in board.minions {
            drawMinion(minion: minion, rect: rect.offsetBy(dx: CGFloat(i) * bounds.width/7, dy: 0))
            i += 1
        }
        
    }
        
    func drawResource(name: String, rect: NSRect) {
        if let image = NSImage(contentsOfFile: Bundle.main.resourcePath! + "/Resources/Battlegrounds/\(name)") {
            image.draw(in: rect)
        }
    }
    
    func drawText(text: String, rect: NSRect) {
        if let font = NSFont(name: "ChunkFive", size: 14) {
            var attributes: [NSAttributedStringKey: Any] = [
                .font: font,
                .foregroundColor: NSColor.white,
                .strokeWidth: -2,
                .strokeColor: NSColor.black
            ]
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            attributes[.paragraphStyle] = paragraph

            text.draw(with: rect, options: NSString.DrawingOptions.truncatesLastVisibleLine,
                                        attributes: attributes)
        }

    }
    func drawMinion(minion: BattlegroundsMinion, rect: NSRect) {
        let backgroundColor = NSColor.init(red: 0x48/255.0, green: 0x7E/255.0, blue: 0xAA/255.0, alpha: 1)
        backgroundColor.set()
        rect.fill()
        
        let rect = rect.insetBy(dx: 2, dy: 2)
        
        let h = rect.height/2
        let imageRect = NSRect(x: rect.minX, y: rect.minY + rect.height - h, width: rect.width, height: h)

        let iconH = h - 6
        let x = rect.minX + (imageRect.width/4 - iconH)/2
        let y = rect.minY + 3
        let iconRect = NSRect(x: x, y: CGFloat(y), width: iconH, height: iconH)
        
        let offset = (iconH - 14)/2
        drawResource(name: "attackminion.png", rect: iconRect)
        drawText(text: "\(minion.attack)", rect: iconRect.offsetBy(dx: 0, dy: offset))

        if minion.divineShield {
            drawResource(name: "divineshield.png", rect: iconRect.offsetBy(dx: imageRect.width/4, dy: 0))
        }
        if minion.poisonous {
            drawResource(name: "poison.png", rect: iconRect.offsetBy(dx: 2*imageRect.width/4, dy: 0))
        }
        drawResource(name: "costhealth.png", rect: iconRect.offsetBy(dx: 3*imageRect.width/4, dy: 0))
        drawText(text: "\(minion.health)", rect: iconRect.offsetBy(dx: 3*imageRect.width/4, dy: 0).offsetBy(dx: 0, dy: offset))

        if let image = cache.first(where: { $0.0 == minion.CardId })?.1 {
            image.draw(in: imageRect)
            
            drawResource(name: "fade.png", rect: imageRect)

            if let font = NSFont(name: "ChunkFive", size: 14) {
                let attributes: [NSAttributedStringKey: Any] = [
                    .font: font,
                    .foregroundColor: NSColor.white,
                    .strokeWidth: -2,
                    .strokeColor: NSColor.black
                ]

                let cardJson = AppDelegate.instance().coreManager.cardJson!
                let name = cardJson.getCard(id: minion.CardId).name
                let textRect = imageRect.insetBy(dx: 8, dy: 10)
                name.draw(with: textRect, options: NSString.DrawingOptions.truncatesLastVisibleLine,
                                            attributes: attributes)
            }

            return
        } else {
            NSColor.black.set()
            imageRect.fill()
        }
        
        let cardId = minion.CardId
        ImageUtils.tile(for: cardId, completion: { [weak self] in
            guard let image = $0 else {
                logger.warning("No image for \(minion.CardId)")
                return
            }

            self?.cache.append((cardId, image))
            if let count = self?.cache.count, count > 7 {
                self?.cache.remove(at: 0)
            }
            DispatchQueue.main.async { [weak self] in
                self?.needsDisplay = true
            }
        })
    }
    
    func drawTurn(turns: Int32) {
        if let font = NSFont(name: "ChunkFive", size: 20) {
            let attributes: [NSAttributedStringKey: Any] = [
                .font: font,
                .foregroundColor: NSColor.white,
                .strokeWidth: -2,
                .strokeColor: NSColor.black
            ]
            let h = CGFloat(20)
            "\(turns) turn(s) ago".draw(with: NSRect(x: 0, y: (bounds.height - h), width: bounds.width, height: h),
                                        options: NSString.DrawingOptions.truncatesLastVisibleLine,
                                        attributes: attributes)
        }
    }
    
    func setBoard(board: BattlegroundsBoard) {
        self.board = board
        self.needsDisplay = true
    }
}
