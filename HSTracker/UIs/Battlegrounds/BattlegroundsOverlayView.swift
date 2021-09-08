//
//  BattlegroundsOverlayView.swift
//  HSTracker
//
//  Created by Martin BONNIN on 30/11/2019.
//  Copyright © 2019 HearthSim LLC. All rights reserved.
//

import Foundation
import RegexUtil

class BattlegroundsOverlayView: NSView {
    var currentIndex = -1
    var _nextOpponentLeaderboardPosition = -1
    
    var leaderboardDeadForText = [NSTextField]()
    var leaderboardDeadForTurnText = [NSTextField]()
    
    let battlegroundsHeroRegex: RegexPattern = ".+_HERO_\\d+(_SKIN_.+)?"
    
    // Adjusts OpponentDeadFor textblocks left by this amount depending on what position they represent on the leaderboard.
    static let leftAdjust = CGFloat(0.00125)
    static let leftOffset = CGFloat(0.01)

    init() {
        super.init(frame: NSRect.zero)
        
        initLeaderboardDeadFor()
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        initLeaderboardDeadFor()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        initLeaderboardDeadFor()
    }

    private func initLeaderboardDeadFor() {
        for _ in 0..<8 {
            var tf = NSTextField()
            tf.isBezeled = false
            tf.isEditable = false
            tf.backgroundColor = NSColor.clear
            tf.textColor = NSColor.white
            tf.alignment = .center
            leaderboardDeadForText.append(tf)
            addSubview(tf)
            
            tf = NSTextField()
            tf.isBezeled = false
            tf.isEditable = false
            tf.backgroundColor = NSColor.clear
            tf.textColor = NSColor.white
            tf.alignment = .center
            leaderboardDeadForTurnText.append(tf)
            addSubview(tf)
        }
    }
    
    func resetNextOpponentLeaderboardPosition() {
        _nextOpponentLeaderboardPosition = -1
    }
    
    func positionDeadForText(nextOpponentLeaderboardPosition: Int = 0) {
        if nextOpponentLeaderboardPosition > 0 {
            _nextOpponentLeaderboardPosition = nextOpponentLeaderboardPosition
        }

        let battlegroundsTileHeight = SizeHelper.battlegroundsTileHeight
        let battlegroundsTileWidth = SizeHelper.battlegroundsTileWidth
        let w = SizeHelper.hearthstoneBoardWidth
        let la = BattlegroundsOverlayView.leftAdjust * w
        let lo = BattlegroundsOverlayView.leftOffset * w
        let h = battlegroundsTileHeight / 4.0
        for i in 0 ..< leaderboardDeadForText.count {
            let r = NSRect(x: 0.0, y: CGFloat((7 - i)) * battlegroundsTileHeight, width: battlegroundsTileWidth, height: h)
            let adj = CGFloat(7 - i) * la + lo
            leaderboardDeadForText[i].frame = r.offsetBy(dx: adj, dy: 2.0 * h + h/2)
            leaderboardDeadForTurnText[i].frame = r.offsetBy(dx: adj, dy: h + h/2)
        }

        if _nextOpponentLeaderboardPosition > 0 {
            let pos = _nextOpponentLeaderboardPosition - 1
            let r = NSRect(x: 0.0, y: CGFloat(7 - pos) * battlegroundsTileHeight, width: battlegroundsTileWidth, height: h)
            let adj = CGFloat(7 - pos) * la + lo + (battlegroundsTileWidth / 3.0)
            leaderboardDeadForText[pos].frame = r.offsetBy(dx: adj, dy: 2.0 * h + h/2)
            leaderboardDeadForTurnText[pos].frame = r.offsetBy(dx: adj, dy: h + h/2)
        }
    }
    
    func updateOpponentDeadForTurns(turns: [Int]) {
        let game = AppDelegate.instance().coreManager.game
        let presentHeroes = game.entities.values.filter({x in x.isHero && x.cardId.match(battlegroundsHeroRegex) && (x.isInPlay || x.isInSetAside)})
        var index = presentHeroes.count - 1
        for text in leaderboardDeadForText {
            text.stringValue = ""
        }
        for text in leaderboardDeadForTurnText {
            text.stringValue = ""
        }
        for turn in turns {
            if index < leaderboardDeadForText.count && index < leaderboardDeadForTurnText.count && index >= 0 {
                leaderboardDeadForText[index].stringValue = "\(turn)"
                leaderboardDeadForTurnText[index].stringValue = turn == 1 ? NSLocalizedString("Turn", comment: "") : NSLocalizedString("Turns", comment: "")
            }
            index -= 1
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        //let backgroundColor: NSColor = NSColor(red: 0x48/255.0, green: 0x7E/255.0, blue: 0xAA/255.0, alpha: 0.3)
        let backgroundColor = NSColor.clear
        backgroundColor.set()
        dirtyRect.fill()
    }
    
    private lazy var trackingArea: NSTrackingArea = NSTrackingArea(rect: NSRect.zero,
                                                                   options: [.inVisibleRect, .activeAlways, .mouseEnteredAndExited, .mouseMoved],
                              owner: self,
                              userInfo: nil)

    override func updateTrackingAreas() {
        logger.debug("update Tracking Area")
        super.updateTrackingAreas()

        if !self.trackingAreas.contains(trackingArea) {
            self.addTrackingArea(trackingArea)
        }
    }

    func displayHero(at: Int) {
        // swiftlint:disable force_cast
        let windowManager = (NSApplication.shared.delegate as! AppDelegate).coreManager.game.windowManager
        // swiftlint:enable force_cast
        
        let game = AppDelegate.instance().coreManager.game
        
        if Settings.showOpponentWarband, let hero = game.entities.values.first(where: { ent in ent.has(tag: .player_leaderboard_place) && ent[.player_leaderboard_place] == at + 1}) {
            let board = game.getSnapshot(opponentHeroCardId: hero.cardId)
            if let board = board {
                windowManager.battlegroundsDetailsWindow.setBoard(board: board)
                let rect = SizeHelper.battlegroundsDetailsFrame()
                windowManager.show(controller: windowManager.battlegroundsDetailsWindow, show: true,
                                   frame: rect, overlay: true)
            } else {
                windowManager.show(controller: windowManager.battlegroundsDetailsWindow, show: false)
            }
        } else {
            windowManager.show(controller: windowManager.battlegroundsDetailsWindow, show: false)
        }
    }

    private var bobsBuddyHidden = false
    
    override func mouseMoved(with event: NSEvent) {
        guard frame.height > 0 else {
            return
        }
        
        let index = 7 - Int(CGFloat(event.locationInWindow.y / (frame.height/8)))
        let game = AppDelegate.instance().coreManager.game

        if let hero = game.entities.values.first(where: { ent in ent[.player_leaderboard_place] == index + 1}), index != currentIndex {
            if hero.cardId != game.playerHeroId {
                for i in 0 ..< leaderboardDeadForText.count {
                    leaderboardDeadForText[i].isHidden = false
                }
                for i in 0 ..< leaderboardDeadForTurnText.count {
                    leaderboardDeadForTurnText[i].isHidden = false
                }
                
                displayHero(at: index)
                currentIndex = index
                let windowManager = AppDelegate.instance().coreManager.game.windowManager
                AppDelegate.instance().coreManager.game.hideBobsBuddy = true
                if windowManager.bobsBuddyPanel.window?.isVisible ?? false {
                    bobsBuddyHidden = true
                    windowManager.show(controller: windowManager.bobsBuddyPanel, show: false)
                }
            } else {
                game.windowManager.show(controller: game.windowManager.battlegroundsDetailsWindow, show: false)
            }
        }
    }

    override func mouseEntered(with event: NSEvent) {
    }

    override func mouseExited(with event: NSEvent) {
        displayHero(at: -1)
        currentIndex = -1
        for i in 0 ..< leaderboardDeadForText.count {
            leaderboardDeadForText[i].isHidden = true
        }
        for i in 0 ..< leaderboardDeadForTurnText.count {
            leaderboardDeadForTurnText[i].isHidden = true
        }
        AppDelegate.instance().coreManager.game.hideBobsBuddy = false
        if bobsBuddyHidden {
            bobsBuddyHidden = false
            let windowManager = AppDelegate.instance().coreManager.game.windowManager
            windowManager.show(controller: windowManager.bobsBuddyPanel, show: true)
        }
    }
}
