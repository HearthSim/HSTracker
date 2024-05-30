//
//  BattlegroundsOverlayView.swift
//  HSTracker
//
//  Created by Martin BONNIN on 30/11/2019.
//  Copyright © 2019 HearthSim LLC. All rights reserved.
//

import Foundation

class BattlegroundsOverlayView: NSView {
    var leaderboardDeadForText = [NSTextField]()
    var leaderboardDeadForTurnText = [NSTextField]()
    
    // Adjusts OpponentDeadFor textblocks left by this amount depending on what position they represent on the leaderboard.
    static let leftAdjust = CGFloat(0.0017)
    static let leftOffset = CGFloat(0.01)
    
    static let nextOpponentRightAdjust = CGFloat(0.023)
    static let duosNextOpponentRightAdjust = CGFloat(0.015)
    
    var _leaderboardHoveredEntityId: Int?

    init() {
        super.init(frame: NSRect.zero)
        
        initLeaderboardDeadFor()
        
        BattlegroundsLeaderboardWatcher.change = { _, args in
            self.setHoveredBattlegroundsEntityId(args.hoveredEntityId)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    
    func positionDeadForText(nextOpponentLeaderboardPosition: Int) {
        let game = AppDelegate.instance().coreManager.game
        
        if game.isBattlegroundsDuosMatch() {
            let battlegroundsDuosTileHeight = SizeHelper.battlegroundsDuosTileHeight
            let battlegroundsDuosTileWidth = SizeHelper.battlegroundsTileWidth
            let h = battlegroundsDuosTileHeight / 4.0
            let w = SizeHelper.hearthstoneBoardWidth
            let la = BattlegroundsOverlayView.leftAdjust
            let lo = BattlegroundsOverlayView.leftOffset
            for i in 0 ..< leaderboardDeadForText.count {
                let j = i / 2
                var left = CGFloat(((leaderboardDeadForText.count / 2) - i)) * BattlegroundsOverlayView.leftAdjust
                if j == nextOpponentLeaderboardPosition - 1 {
                    left += BattlegroundsOverlayView.duosNextOpponentRightAdjust
                }
                left = SizeHelper.getScaledXPos(left, width: SizeHelper.hearthstoneWindow.width, ratio: SizeHelper.screenRatio)
                let r = NSRect(x: 0.0, y: CGFloat((3 - i)) * battlegroundsDuosTileHeight + CGFloat(3 - j) * SizeHelper.battlegroundsDuosSpacingHeight, width: battlegroundsDuosTileWidth, height: h)
                leaderboardDeadForText[i].frame = r.offsetBy(dx: left, dy: 2.0 * h + h/2)
                leaderboardDeadForTurnText[i].frame = r.offsetBy(dx: left, dy: h + h/2)
            }
        } else {
            let battlegroundsTileHeight = SizeHelper.battlegroundsTileHeight
            let battlegroundsTileWidth = SizeHelper.battlegroundsTileWidth
            let h = battlegroundsTileHeight / 4.0
            for i in 0 ..< leaderboardDeadForText.count {
                var left = CGFloat(((leaderboardDeadForText.count / 2) - i)) * BattlegroundsOverlayView.leftAdjust
                if i == nextOpponentLeaderboardPosition - 1 {
                    left += BattlegroundsOverlayView.nextOpponentRightAdjust
                }
                left = SizeHelper.getScaledXPos(left, width: SizeHelper.hearthstoneWindow.width, ratio: SizeHelper.screenRatio)
                let r = NSRect(x: 0.0, y: CGFloat((7 - i)) * battlegroundsTileHeight, width: battlegroundsTileWidth, height: h)
                leaderboardDeadForText[i].frame = r.offsetBy(dx: left, dy: 2.0 * h + h/2)
                leaderboardDeadForTurnText[i].frame = r.offsetBy(dx: left, dy: h + h/2)
            }
        }
    }
    
    func updateOpponentDeadForTurns(turns: [Int]) {
        let game = AppDelegate.instance().coreManager.game
        var index = game.battlegroundsHeroCount() - 1
        for text in leaderboardDeadForText {
            text.stringValue = ""
        }
        for text in leaderboardDeadForTurnText {
            text.stringValue = ""
        }
        for turn in turns {
            if index < leaderboardDeadForText.count && index < leaderboardDeadForTurnText.count && index >= 0 {
                leaderboardDeadForText[index].stringValue = "\(turn)"
                leaderboardDeadForTurnText[index].stringValue = turn == 1 ? String.localizedString("Turn", comment: "") : String.localizedString("Turns", comment: "")
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

    private func setHoveredBattlegroundsEntityId(_ entityId: Int?) {
        _leaderboardHoveredEntityId = entityId
        DispatchQueue.main.async {
            self.update()
        }
    }

    func displayHero(entityId: Int?) {
        let windowManager = AppDelegate.instance().coreManager.game.windowManager
        
        let game = AppDelegate.instance().coreManager.game
        
        if Settings.showOpponentWarband, let entityId, let hero = game.entities[entityId], let board = game.getBattlegroundsBoardStateFor(id: hero.id) {
            windowManager.battlegroundsDetailsWindow.setBoard(board: board)
            var heroPowers = game.player.board.filter { x in x.isHeroPower }.compactMap { x in x.cardId }
            if heroPowers.count > 0 && game.gameEntity?[.step] ?? 0 <= Step.begin_mulligan.rawValue {
                let heroes = game.player.playerEntities.filter { x in x.isHero && (x.has(tag: .bacon_hero_can_be_drafted) || x.has(tag: .bacon_skin))}
                heroPowers = heroes.compactMap { x in Cards.by(dbfId: x[.hero_power], collectible: false)?.id }
            }
            windowManager.battlegroundsTierOverlay.tierOverlay.onHeroPowers(heroPowers: heroPowers)
            let rect = SizeHelper.battlegroundsDetailsFrame()
            windowManager.show(controller: windowManager.battlegroundsDetailsWindow, show: true,
                               frame: rect, overlay: true)
        } else {
            windowManager.show(controller: windowManager.battlegroundsDetailsWindow, show: false)
        }
    }

    private var bobsBuddyHidden = false
    private var battlegroundsTierHidden = false
    private var battlegroundsTurnHidden = false

    @MainActor
    func update() {
        let game = AppDelegate.instance().coreManager.game
        
        if game.turnNumber() == 0 {
            return
        }
        
        var shouldShowOpponentInfo = false

        if let heroEntityId = _leaderboardHoveredEntityId {
            // check if it's the team mate
            if let entity = game.entities[heroEntityId], !(entity.isControlled(by: game.player.id) || (game.isBattlegroundsDuosMatch() && entity[.bacon_duo_team_id] == game.playerEntity?[.bacon_duo_team_id])) {
                shouldShowOpponentInfo = true
            }
        }

        if shouldShowOpponentInfo {
            for i in 0 ..< leaderboardDeadForText.count {
                leaderboardDeadForText[i].isHidden = false
            }
            for i in 0 ..< leaderboardDeadForTurnText.count {
                leaderboardDeadForTurnText[i].isHidden = false
            }
            
            displayHero(entityId: _leaderboardHoveredEntityId)
            let windowManager = game.windowManager
            
            game.hideBobsBuddy = true
            game.hideBattlegroundsTier = true
            game.hideBattlegroundsTurn = true
            
            if windowManager.bobsBuddyPanel.window?.isVisible ?? false {
                bobsBuddyHidden = true
                windowManager.show(controller: windowManager.bobsBuddyPanel, show: false)
            }
            if windowManager.battlegroundsTierOverlay.window?.isVisible ?? false {
                battlegroundsTierHidden = true
                windowManager.show(controller: windowManager.battlegroundsTierOverlay, show: false)
            }
            if windowManager.turnCounter.window?.isVisible ?? false {
                battlegroundsTurnHidden = true
                windowManager.show(controller: windowManager.turnCounter, show: false)
            }
        } else {
            displayHero(entityId: nil)
            
            for i in 0 ..< leaderboardDeadForText.count {
                leaderboardDeadForText[i].isHidden = true
            }
            for i in 0 ..< leaderboardDeadForTurnText.count {
                leaderboardDeadForTurnText[i].isHidden = true
            }
            let windowManager = game.windowManager
            
            game.hideBobsBuddy = false
            if bobsBuddyHidden {
                bobsBuddyHidden = false
                windowManager.show(controller: windowManager.bobsBuddyPanel, show: true)
            }
            game.hideBattlegroundsTier = false
            if battlegroundsTierHidden {
                battlegroundsTierHidden = false
                windowManager.show(controller: windowManager.battlegroundsTierOverlay, show: true)
            }
            game.hideBattlegroundsTurn = false
            if battlegroundsTurnHidden {
                battlegroundsTurnHidden = false
                windowManager.show(controller: windowManager.turnCounter, show: true)
            }
        }
    }
}
