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

class MercAbilityData {
    var entity: Entity?
    var card: Card?
    var active = false
    var gameTurn = 0
    var hasTiers = false
    
    init(entity: Entity?, card: Card?, active: Bool, gameTurn: Int, hasTiers: Bool) {
        self.entity = entity
        self.card = card
        self.active = active
        self.gameTurn = gameTurn
        self.hasTiers = hasTiers
    }
}

private func getMercAbilities(player: Player) -> [[MercAbilityData]] {
    let game = AppDelegate.instance().coreManager.game

    let result: [[MercAbilityData]] = player.board.filter { x in x.isMinion }.sorted { (a, b) in a.zonePosition < b.zonePosition }.compactMap { entity in
        let dbfId = entity.card.dbfId
        let actualAbilities = player.playerEntities.filter { x in x[.lettuce_ability_owner] == entity.id && !x.has(tag: .lettuce_is_equipment) && !x.has(tag: .dont_show_in_history) && x.hasCardId }
        let staticAbilities = dbfId != 0 ? RemoteConfig.mercenaries?.first { x in x.skinDbfIds.contains(dbfId)}?.specializations.first?.abilities ?? [MercenaryAbility]() : [MercenaryAbility]()
        var data = [MercAbilityData]()
        let max_ = min(3, max(staticAbilities.count, actualAbilities.count))
        
        for i in 0 ..< max_ {
            let staticAbility = i < staticAbilities.count ? staticAbilities[i] : nil
            let actual = staticAbility != nil ? actualAbilities.first(where: { x in staticAbility!.tiers.any { t in t.dbf_id == x.card.dbfId }}) : actualAbilities.first { x in data.all({ d in d.entity?.cardId != x.cardId }) }
            if let actual = actual {
                let active = entity[.lettuce_ability_tile_visual_self_only] == actual.id || entity[.lettuce_ability_tile_visual_all_visible] == actual.id
                data.append(MercAbilityData(entity: actual, card: nil, active: active, gameTurn: 0, hasTiers: false))
            } else if let staticAbility = staticAbility {
                if let card = actual?.card ?? Cards.by(dbfId: staticAbility.tiers.last?.dbf_id ?? 0, collectible: false) {
                    let gameTurn = game.gameEntity?[.turn] ?? 0
                    data.append(MercAbilityData(entity: nil, card: card, active: false, gameTurn: gameTurn, hasTiers: staticAbility.tiers.count > 1))
                }
            }
        }
        return data
    }
    return result
}

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
    
    private func clearMercHover() {
        NotificationCenter.default
            .post(name: Notification.Name(rawValue: Events.hide_floating_card), object: nil,
                  userInfo: [ "card": card as Any])
        card = nil
    }
    
    private func setFlavorTextEntity(entity: Entity) {
        guard Settings.showFlavorText else {
            return
        }
        let card = entity.info.latestCardId == entity.cardId
            ? entity.card : Cards.any(byId: entity.info.latestCardId)
        guard let card = card else {
            return
        }
        if card.flavor.isEmpty {
            return
        }
        guard let font = NSFont(name: "ChunkFive", size: 14.0), let font12 = NSFont(name: "ChunkFive", size: 12.0) else {
            return
        }
        let game = AppDelegate.instance().coreManager.game
        let flavorWindow = game.windowManager.flavorText
        let style = NSMutableParagraphStyle()
        style.alignment = NSTextAlignment.center

        let str = card.flavor.htmlToAttributedString ?? NSMutableAttributedString()
        str.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: str.length))
        str.addAttribute(.font, value: font12, range: NSRange(location: 0, length: str.length))
        flavorWindow.flavorTextLabel.cell = VerticallyAlignedTextFieldCell()
        flavorWindow.flavorTextLabel.attributedStringValue = str
        let cardNameStr = NSMutableAttributedString(string: card.name, attributes: [NSAttributedString.Key.strokeWidth: -4.0, NSAttributedString.Key.strokeColor: NSColor.black, NSAttributedString.Key.foregroundColor: NSColor.white, NSAttributedString.Key.font: font, NSAttributedString.Key.paragraphStyle: style])
        flavorWindow.cardNameLabel.attributedStringValue = cardNameStr
        let rect = SizeHelper.flavorTextFrame()
        game.windowManager.show(controller: flavorWindow, show: true, frame: rect, title: nil, overlay: true)
    }
    
    override func mouseEntered(with event: NSEvent) {
        if let entity = entity {
            let game = AppDelegate.instance().coreManager.game
            
            guard !game.gameEnded else {
                return
            }
            
            if !game.isMercenariesMatch() && (game.player.board.count == 0 && game.opponent.board.count == 0 && game.player.handCount == 0 || game.gameEnded) {
                // hide flavor text
                return
            }
            if game.isMercenariesMatch() && (game.gameEntity?[.step] == Step.main_combat.rawValue || !showMercenaryHover()) {
                parent.mousedOver = false
                clearMercHover()
                parent.clearAbilitiesVisibility()
                return
            }
            parent.updateAbilitiesVisibility(view: self)

            if !game.isMercenariesMatch() {
                setFlavorTextEntity(entity: entity)
                return
            }
            let player: Player = playerType == .player ? game.player : game.opponent
            let data = getMercAbilities(player: player)
            let abilities = data[entity.zonePosition - 1]
            let hsFrame = SizeHelper.hearthstoneWindow.frame
            let h = hsFrame.height * 0.3
            let dh = hsFrame.height / 3.0
            let delta = (dh - h) / 2.0
            let nh = min(h, 388.0)
            let w = (CGFloat(nh) / CGFloat(388)) * 256.0
            let hoverFrame = NSRect(x: 0.0, y: 0.0, width: w, height: nh)
            let x = hsFrame.maxX - hoverFrame.width
            let max_ = min(3, abilities.count)
            for i in 0..<max_ {
                let abilityData = abilities[i]
                if let card = abilityData.entity?.card ?? abilityData.card {
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
                                          "index": i,
                                          "disableTimeout": true])
                }
            }
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        parent.mousedOver = false
        parent.clearAbilitiesVisibility()
        clearMercHover()
        let game = AppDelegate.instance().coreManager.game
        if !game.isMercenariesMatch() {
            game.windowManager.show(controller: game.windowManager.flavorText, show: false)
        }
    }
}

class BoardOverlayView: NSView {
    var minions: [BoardMinionView] = []
    var abilities: [MercenariesAbilitiesView] = []
    var mousedOver: Bool = false
    var updated: Date?
    var playerType: PlayerType = .player
    
    init() {
        super.init(frame: NSRect.zero)
        
        addMinions()
    }
    
    func updateBoardState(player: Player) {
        if let updated = updated {
            if updated.timeIntervalSinceNow > -0.05 {
                return
            }
        }
        updated = Date()
        let game = AppDelegate.instance().coreManager.game
        let board = player.board.filter({ x in x.isMinion }).sorted(by: { (a, b) in a.zonePosition < b.zonePosition })

        if game.isMercenariesMatch() && mousedOver && game.gameEntity?[.step] == Step.main_combat.rawValue {
            if mousedOver {
                NotificationCenter.default
                    .post(name: Notification.Name(rawValue: Events.hide_floating_card), object: nil,
                          userInfo: [ "card": minions[0].card as Any])
                mousedOver = false
            }
            clearAbilitiesVisibility()
            return
        }
        let cnt = board.count
        if cnt == 0 || game.gameEnded {
            isHidden = true
        } else {
            isHidden = false
        }
        let frame = SizeHelper.opponentBoardOverlay()
        let w = SizeHelper.minionWidth
        let m = game.isMercenariesMatch() ? SizeHelper.mercenariesMinionMargin :  SizeHelper.minionMargin
        let abilitySize = SizeHelper.abilitySize()
        let overlayHeight = SizeHelper.boardOverlayHeight()
        let yOff = playerType == .player ? abilitySize + overlayHeight * 0.14: 0
        let aOff = playerType == .player ? 0 : overlayHeight + overlayHeight * 0.12
        let x = (frame.width - CGFloat(cnt) * w - 2.0 * CGFloat(cnt) * m) / 2.0
        let rect = NSRect(x: x + m, y: yOff, width: w, height: overlayHeight)
        let step = game.gameEntity?[.step] ?? 0
        let showAbilities = game.isMercenariesMatch() && (step == Step.main_action.rawValue || step == Step.main_pre_action.rawValue)
        let showPlayerAbilities = playerType == .player ? Settings.showMercsPlayerAbilities : Settings.showMercsOpponentAbilities
        let mercAbilities = showAbilities && showPlayerAbilities ? getMercAbilities(player: player) : nil
        for i in 0..<cnt {
            let fr = rect.offsetBy(dx: CGFloat(i) * (w + 2 * m), dy: 0)
            minions[i].frame = fr
            minions[i].entity = board[i]
            minions[i].playerType = playerType
            if !minions[i].isDescendant(of: self) {
                addSubview(minions[i])
            }
            
            if game.isMercenariesMatch() {
                let abilityRect = NSRect(x: fr.minX, y: aOff, width: fr.width, height: abilitySize)
                abilities[i].frame = abilityRect
                if !abilities[i].isDescendant(of: self) {
                    addSubview(abilities[i])
                }
                
                abilities[i].setAbilities(abilities: mercAbilities?[i], abilitySize: abilitySize, parentFrame: abilityRect)
            }
        }
        for i in cnt..<7 {
            minions[i].frame = NSRect.zero
            minions[i].entity = nil
            minions[i].playerType = playerType
            if minions[i].isDescendant(of: self) {
                minions[i].removeFromSuperview()
            }
            if game.isMercenariesMatch() {
                abilities[i].frame = NSRect.zero
                if abilities[i].isDescendant(of: self) {
                    abilities[i].removeFromSuperview()
                }
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
            let ability = MercenariesAbilitiesView()
            abilities.append(ability)
            addSubview(ability)
        }
    }
    
    func updateAbilitiesVisibility(view: BoardMinionView) {
        if let hoverIndex = minions.firstIndex(of: view) {
            let game = AppDelegate.instance().coreManager.game
            let player = playerType == .player ? game.player : game.opponent
            let excludeIndex = playerType == .player ? game.gameEntity?.has(tag: .allow_move_minion) ?? false : false
            let board = player?.board.filter({ x in x.isMinion }).sorted(by: { (a, b) in a.zonePosition < b.zonePosition }) ?? [Entity]()
            let cnt = board.count

            let center = (cnt + 1) / 2 - 1
            
            for i in 0 ..< 7 {
                if hoverIndex <= center {
                    // tooltip to the right
                    if i <= hoverIndex && game.isMercenariesMatch() {
                        abilities[i].isHidden = false
                    } else {
                        abilities[i].isHidden = true
                    }
                } else {
                    // tooltip to the left
                    if i >= hoverIndex && game.isMercenariesMatch() {
                        abilities[i].isHidden = false
                    } else {
                        abilities[i].isHidden = true
                    }
                }
            }
            if excludeIndex || !game.isMercenariesMatch() {
                abilities[hoverIndex].isHidden = true
            }
        }
    }
    
    func clearAbilitiesVisibility() {
        for ability in abilities {
            ability.isHidden = false
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
    
    func setPlayerType(playerType: PlayerType) {
        view.playerType = playerType
    }
}
