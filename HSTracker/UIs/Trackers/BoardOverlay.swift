//
//  CollectionFeedback.swift
//  HSTracker
//
//  Created by Martin BONNIN on 13/11/2019.
//  Copyright © 2019 HearthSim LLC. All rights reserved.
//

import Foundation
import TextAttributes
import AppKit

class BoardMinionView: NSView {
    var entity: Entity?
    var card: Card?
    let parent: BoardOverlayView
    var playerType: PlayerType = .player
    
    init(parent: BoardOverlayView) {
        self.parent = parent
        super.init(frame: NSRect.zero)
        
//        wantsLayer = true
//        layer?.borderWidth = 2
//        layer?.borderColor = CGColor.black
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    override func draw(_ dirtyRect: NSRect) {
//        super.draw(dirtyRect)
//
//        let curve = NSBezierPath(rect: frame)
//        NSColor.black.set()
//        curve.stroke()
//    }
    
    private lazy var trackingArea: NSTrackingArea = NSTrackingArea(rect: NSRect.zero,
                                                                   options: [.inVisibleRect, .activeAlways, .mouseEnteredAndExited, .mouseMoved],
                              owner: self,
                              userInfo: nil)

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if !self.trackingAreas.contains(trackingArea) {
            self.addTrackingArea(trackingArea)
        }
    }
    
    private func showMercenaryHover() -> Bool {
        if playerType == .player {
            return Settings.showMercsPlayerHover
        }
        return Settings.showMercsOpponentHover
    }
    
    override func mouseEntered(with event: NSEvent) {
        if let entity = entity {
            let game = AppDelegate.instance().coreManager.game
            
            guard !game.gameEnded else {
                return
            }
            
            if !game.isMercenariesMatch() && (game.player.board.count == 0 && game.opponent.board.count == 0 && game.player.handCount == 0) {
                return
            }
            if game.isMercenariesMatch() && (game.gameEntity?[.step] == Step.main_combat.rawValue || !showMercenaryHover()) {
                return
            }
            let actualAbilities = AppDelegate.instance().coreManager.game.opponent.playerEntities.filter { x in x[.lettuce_ability_owner] == entity.id  && !entity.has(tag: .lettuce_is_equipment) && x.hasCardId && !x.has(tag: .dont_show_in_history)}
            
            let staticAbilities = RemoteConfig.mercenaries?.first { x in x.art_variation_ids.contains(entity.cardId)}?.abilities ?? [MercAbility]()
            let hsFrame = SizeHelper.hearthstoneWindow.frame
            let h = hsFrame.height * 0.3
            let dh = hsFrame.height / 3.0
            let delta = (dh - h) / 2.0
            let nh = min(h, 388.0)
            let w = (CGFloat(nh) / CGFloat(388)) * 256.0
            let hoverFrame = NSRect(x: 0.0, y: 0.0, width: w, height: nh)
            let x = hsFrame.maxX - hoverFrame.width
            let max_ = min(3, staticAbilities.count)
            for i in 0..<max_ {
                let ability = staticAbilities[i]
                let actual = actualAbilities.first { x in ability.tier_ids.contains(x.cardId) }
                if let card = actual?.card ?? Cards.any(byId: ability.tier_ids.last ?? "") {
                    let frame = [x, hsFrame.maxY + delta - CGFloat(i+1) * h, hoverFrame.width, hoverFrame.height]
                    if i == 0 {
                        self.card = card
                        self.parent.mousedOver = true
                    }
                    NotificationCenter.default
                        .post(name: Notification.Name(rawValue: Events.show_floating_card), object: nil,
                              userInfo: [ "card": card as Any,
                                          "frame": frame,
                                          "useFrame": true,
                                          "index": i])
                }
            }
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        self.parent.mousedOver = false
        NotificationCenter.default
            .post(name: Notification.Name(rawValue: Events.hide_floating_card), object: nil,
                  userInfo: [ "card": self.card as Any])
        self.card = nil
    }
}

class BoardOverlayView: NSView {
    var minions: [BoardMinionView] = []
    var mousedOver: Bool = false
    
    init() {
        super.init(frame: NSRect.zero)
        
        addMinions()
    }

    func updateBoardState(player: Player) {
        let game = AppDelegate.instance().coreManager.game
        let playerType = (player.id == game.player.id) ? PlayerType.player : PlayerType.opponent
        if game.isMercenariesMatch() && mousedOver && game.gameEntity?[.step] == Step.main_combat.rawValue && minions.count > 0 {
            NotificationCenter.default
                .post(name: Notification.Name(rawValue: Events.hide_floating_card), object: nil,
                      userInfo: [ "card": minions[0].card as Any])
            mousedOver = false
        }
        let oppBoard = player.board.filter({ x in x.isMinion }).sorted(by: { (a, b) in a[.zone_position] < b[.zone_position] })
        let cnt = oppBoard.count
        let frame = SizeHelper.opponentBoardOverlay()
        let w = SizeHelper.minionWidth
        let m = SizeHelper.mercenariesMinionMargin
        let x = (frame.width - CGFloat(cnt) * w - 2.0 * CGFloat(cnt) * m) / 2.0
        let rect = NSRect(x: x + m, y: 0, width: w, height: frame.height)
        for i in 0..<cnt {
            minions[i].frame = rect.offsetBy(dx: CGFloat(i) * (w + 2 * m), dy: 0)
            minions[i].entity = oppBoard[i]
            minions[i].playerType = playerType
            if !minions[i].isDescendant(of: self) {
                addSubview(minions[i])
            }
        }
        for i in cnt..<7 {
            minions[i].frame = NSRect.zero
            minions[i].entity = nil
            minions[i].playerType = playerType
            if minions[i].isDescendant(of: self) {
                minions[i].removeFromSuperview()
            }
        }
        needsLayout = true
        needsDisplay = true
    }
    
    func addMinions() {
        for _ in 0..<7 {
            let minion = BoardMinionView(parent: self)
            minions.append(minion)
            addSubview(minion)
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

//    override func draw(_ dirtyRect: NSRect) {
//        super.draw(dirtyRect)
//        let backgroundColor: NSColor = NSColor(red: 0x48/255.0, green: 0x7E/255.0, blue: 0xAA/255.0, alpha: 0.3)
//        //let backgroundColor = NSColor.clear
//        backgroundColor.set()
//        dirtyRect.fill()
//    }
    
    override func isMousePoint(_ point: NSPoint, in rect: NSRect) -> Bool {
        return false
    }
}

class BoardOverlay: OverWindowController {
    
    override var alwaysLocked: Bool { true }
    
    var view = BoardOverlayView()
        
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window!.contentView = view
        //self.window!.backgroundColor = NSColor.brown
    }
    
    func updateBoardState(player: Player) {
        view.updateBoardState(player: player)
    }
}
