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
    var combatHistory: [MirrorCombatHistory] = []
    var playerId: Int = 0
    var heroId: String = ""
    
    init() {
        super.init(frame: NSRect.zero)
        logger.debug("BattlegroundsDetailsView created")
        
        let rect = NSRect(x: 0, y: 120, width: 100, height: 110).insetBy(dx: 0, dy: 0)
        for i in 0..<7 {
            let view = BattlegroundsMinionView(frame: rect.offsetBy(dx: CGFloat(i) * 100, dy: 0))
            boardMinions.append(view)
            addSubview(view)
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer?.masksToBounds = true
        self.layer?.cornerRadius = 3.0
        self.layer?.borderColor = CGColor(red: 0x40/255.0, green: 0x43/255.0, blue: 0x45/255.0, alpha: 1.0)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        //let backgroundColor: NSColor = NSColor.clear
        let backgroundColor = NSColor.init(red: 0x23/255.0, green: 0x27/255.0, blue: 0x2A/255.0, alpha: 0.8)
        
        backgroundColor.set()
        dirtyRect.fill()
        
        if let board = self.board {
            drawTurn(turns: AppDelegate.instance().coreManager.game.turnNumber() - board.turn, boardTurn: board.turn)
            if Settings.showTavernTriples {
                drawTavernUpgrades()
                drawTriples()
            }
            drawCombatHistory()
        }
    }
    
    func reset() {
        board = nil
    }
    
    func drawText(text: String, rect: NSRect) {
        if let font = NSFont(name: "ChunkFive", size: 14) {
            var attributes: [NSAttributedString.Key: Any] = [
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

    func drawTurn(turns: Int, boardTurn: Int) {
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
            text.draw(with: NSRect(x: 10, y: 100, width: bounds.width-10, height: h),
                                        options: NSString.DrawingOptions.truncatesLastVisibleLine,
                                        attributes: attributes)
        }
    }
    
    static let levelSymbols = [
        "1️⃣", "2️⃣", "3️⃣", "4️⃣", "5️⃣", "6️⃣"
    ]
    
    func drawTavernUpgrades() {
        let techLevels = board?.techLevel.enumerated().filter({ $0.element != 0 }).map({ (idx, turn) in
            "\(BattlegroundsDetailsView.levelSymbols[idx]): \(turn)"
        }).joined(separator: " ") ?? ""
        if techLevels.count > 0, let font = NSFont(name: "Courier", size: 20) {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.white,
                .strokeWidth: -2,
                .strokeColor: NSColor.black
            ]
            let h = CGFloat(20)
            "⬆️: \(techLevels)".draw(with: NSRect(x: 10, y: 70, width: bounds.width-10, height: h),
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
            "⏫: \(triples)".draw(with: NSRect(x: 10, y: 40, width: bounds.width-10, height: h),
                                        options: NSString.DrawingOptions.truncatesLastVisibleLine,
                                        attributes: attributes)
        }
    }
    
    func drawCombatHistory() {
        guard let font = NSFont(name: "Courier", size: 20) else {
            return
        }
        if combatHistory.count == 0 {
            return
        }
        let attributesRed: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.red,
            .strokeWidth: -2,
            .strokeColor: NSColor.black
        ]
        let attributesGreen: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.green,
            .strokeWidth: -2,
            .strokeColor: NSColor.black
        ]
        let attributesWhite: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white,
            .strokeWidth: -2,
            .strokeColor: NSColor.black
        ]

        let history = NSMutableAttributedString(string: "⚔️: ", attributes: attributesWhite)
        var index = combatHistory.count - 1
        var count = 0
        
        while count < 10 && index >= 0 {
            let h = combatHistory[index]
            
            let target = h.damageTarget.intValue
            let dmg = h.damage.intValue == 100000 ? 0 : h.damage.intValue
            let opp = h.opponentId.intValue
            let oppId = AppDelegate.instance().coreManager.game.battlegroundsHeroMap[opp]
            let damage = " \(dmg) "
            if let cardId = oppId, let image = ImageUtils.cachedArt(cardId: cardId) {
                let attachment = NSTextAttachment()
                attachment.image = image.crop(rect: CGRect(x: 48, y: 16, width: 160, height: 160    )).resized(to: NSSize(width: 20, height: 20))
                history.append(NSAttributedString(attachment: attachment))
            } else {
                logger.error("Failed to get image opponent for \(opp), using Kel'Thuzad")
                if let image = ImageUtils.cachedArt(cardId: "TB_BaconShop_HERO_KelThuzad") {
                    let attachment = NSTextAttachment()
                    attachment.image = image.crop(rect: CGRect(x: 48, y: 16, width: 160, height: 160    )).resized(to: NSSize(width: 20, height: 20))
                    history.append(NSAttributedString(attachment: attachment))
                }
            }
            
            if dmg == 0 {
                history.append(NSAttributedString(string: damage, attributes: attributesWhite))
            } else if target == playerId {
                history.append(NSAttributedString(string: damage, attributes: attributesRed))
            } else {
                history.append(NSAttributedString(string: damage, attributes: attributesGreen))
            }
            
            count += 1
            index -= 1
        }
        history.draw(with: NSRect(x: 10, y: 10, width: bounds.width-10, height: CGFloat(20)),
                                    options: NSString.DrawingOptions.truncatesLastVisibleLine)
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
    
    func setCombatHistory(id: Int, cardId: String, history: [MirrorCombatHistory]) {
        self.combatHistory = history
        self.playerId = id
        self.heroId = cardId
        logger.debug("Setting combat history for player \(id) with \(self.combatHistory.count) entries")
        self.needsDisplay = true
    }
}
