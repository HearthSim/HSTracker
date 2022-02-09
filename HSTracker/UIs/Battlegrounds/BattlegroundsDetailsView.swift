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
    
    init() {
        super.init(frame: NSRect.zero)
        logger.debug("BattlegroundsDetailsView created")
        
        let rect = NSRect(x: 0, y: 90, width: 100, height: 110).insetBy(dx: 0, dy: 0)
        for i in 0..<7 {
            let view = BattlegroundsMinionView(frame: rect.offsetBy(dx: CGFloat(i) * 100, dy: 0))
            boardMinions.append(view)
            addSubview(view)
        }

        self.wantsLayer = true
        self.layer?.backgroundColor = CGColor(red: 0x23/255.0, green: 0x27/255.0, blue: 0x2a/255.0, alpha: 0.8)
        self.layer?.cornerRadius = 10.0
        self.layer?.borderColor = CGColor(red: 0x40/255.0, green: 0x43/255.0, blue: 0x45/255.0, alpha: 1.0)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if let board = self.board {
            drawTurn(turns: AppDelegate.instance().coreManager.game.turnNumber() - board.turn, boardTurn: board.turn, buddies: board.buddiesGained)
            if Settings.showTavernTriples {
                drawTavernUpgrades()
                drawTriples()
            }
        }
    }
    
    func reset() {
        board = nil
    }
    
    func drawTurn(turns: Int, boardTurn: Int, buddies: Int) {
        if let font = NSFont(name: "ChunkFive", size: 20) {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.white,
                .strokeWidth: -2,
                .strokeColor: NSColor.black
            ]
            let h = CGFloat(20)
            let text = boardTurn != -1 ?
                String.localizedStringWithFormat(NSLocalizedString("%d turn(s) ago", comment: ""), turns) :
                NSLocalizedString("You have not fought this opponent", comment: "")
            text.draw(with: NSRect(x: 10, y: 70, width: bounds.width - 10, height: h),
                                        options: NSString.DrawingOptions.truncatesLastVisibleLine,
                                        attributes: attributes)
        }
    }
    
    static let levelSymbols = [
        "1️⃣", "2️⃣", "3️⃣", "4️⃣", "5️⃣", "6️⃣"
    ]
    
    func drawTavernUpgrades() {
        let buddies = "🅱️: \(board?.buddiesGained ?? 0)"
        let techLevels = board?.techLevel.enumerated().filter({ $0.element != 0 }).map({ (idx, turn) in
            "\(BattlegroundsDetailsView.levelSymbols[idx]): \(turn)"
        }).joined(separator: " ").appending(" ").appending(buddies) ?? buddies
        if techLevels.count > 0, let font = NSFont(name: "Courier", size: 20) {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.white,
                .strokeWidth: -2,
                .strokeColor: NSColor.black
            ]
            let h = CGFloat(20)
            "⬆️: \(techLevels)".draw(with: NSRect(x: 10, y: 40, width: bounds.width - 10, height: h),
                                        options: NSString.DrawingOptions.truncatesLastVisibleLine,
                                        attributes: attributes)
        }
    }
    
    func drawTriples() {
        let triples = board?.triples.enumerated().filter({ $0.element != 0 }).map({ (idx, triple) in
            "\(BattlegroundsDetailsView.levelSymbols[idx]): \(triple)"
        }).joined(separator: " ") ?? ""

        if triples.count > 0, let font = NSFont(name: "Courier", size: 20) {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.white,
                .strokeWidth: -2,
                .strokeColor: NSColor.black
            ]
            let h = CGFloat(20)
            "⏫: \(triples)".draw(with: NSRect(x: 10, y: 10, width: bounds.width - 10, height: h),
                                        options: NSString.DrawingOptions.truncatesLastVisibleLine,
                                        attributes: attributes)
        }
    }
    
    func setBoard(board: BoardSnapshot) {
        self.board = board
        logger.debug("Setting board with \(board.entities.count) entities")

        var i = 0
        for entity in board.entities {
            boardMinions[i].entity = entity
            boardMinions[i].needsDisplay = true
            i += 1
        }
        while i < 7 {
            boardMinions[i].entity = nil
            boardMinions[i].needsDisplay = true
            i += 1
        }
        self.needsDisplay = true
    }
}
