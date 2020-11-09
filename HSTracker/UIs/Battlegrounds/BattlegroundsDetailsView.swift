//
//  BattlegroundsOverlayView.swift
//  HSTracker
//
//  Created by Martin BONNIN on 30/11/2019.
//  Copyright © 2019 HearthSim LLC. All rights reserved.
//

import Foundation

class BattlegroundsDetailsView: NSView {
    var board: BoardSnapshot?
    var cache: [(String, NSImage)] = []
    var boardMinions: [BattlegroundsMinionView] = []
    
    override var intrinsicContentSize: NSSize {
        return NSSize(width: 100*7, height: 140)
    }

    init() {
        super.init(frame: NSRect.zero)
        logger.debug("BattlegroundsDetailsView created")
        
        let rect = NSRect(x: 0, y: 30, width: 100, height: 110).insetBy(dx: 0, dy: 0)
        for i in 0..<7 {
            let view = BattlegroundsMinionView(frame: rect.offsetBy(dx: CGFloat(i) * 100, dy: 0))
            boardMinions.append(view)
            addSubview(view)
        }
        translatesAutoresizingMaskIntoConstraints = false
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
            drawTurn(turns: AppDelegate.instance().coreManager.game.turnNumber() - board.turn)
        }
    }
    
    func reset() {
        board = nil
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

    func drawTurn(turns: Int) {
        if let font = NSFont(name: "ChunkFive", size: 20) {
            let attributes: [NSAttributedStringKey: Any] = [
                .font: font,
                .foregroundColor: NSColor.white,
                .strokeWidth: -2,
                .strokeColor: NSColor.black
            ]
            let h = CGFloat(20)
            "\(turns) turn(s) ago".draw(with: NSRect(x: 0, y: 0, width: bounds.width, height: h),
                                        options: NSString.DrawingOptions.truncatesLastVisibleLine,
                                        attributes: attributes)
        }
    }
    
    func setBoard(board: BoardSnapshot) {
        self.board = board
        logger.debug("Setting board with \(self.board!.entities.count) entities")

        var i = 0
        for entity in board.entities {
            boardMinions[i].entity = entity
            i += 1
        }
        while i < 7 {
            boardMinions[i].entity = nil
            i += 1
        }
        self.needsDisplay = true
    }
}
