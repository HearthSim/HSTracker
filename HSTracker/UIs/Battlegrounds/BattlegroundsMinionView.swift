//
//  BattlegroundsMinionView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/2/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

/// What one minion slot draws. Normally taken from a board `Entity`, but the last known
/// board popup also draws a Deity, which has no entity of its own until it awakens - HDT
/// builds a BattlegroundsMinionViewModel by hand for that.
struct BattlegroundsMinionDisplay {
    var cardId: String
    var attack: Int
    var health: Int
    var originalAttack: Int
    var originalHealth: Int
    var isPremium = false
    var hasReborn = false
    var hasTaunt = false
    var hasDeathrattle = false
    var hasPoisonous = false
    var hasDivineShield = false
    var hasVenomous = false

    init(entity: Entity) {
        let isPremium = entity.has(tag: .premium)
        cardId = entity.cardId
        attack = entity.attack
        health = entity.health
        originalAttack = isPremium ? entity.card.attack * 2 : entity.card.attack
        originalHealth = isPremium ? entity.card.health * 2 : entity.card.health
        self.isPremium = isPremium
        hasReborn = entity.has(tag: .reborn)
        hasTaunt = entity.has(tag: .taunt)
        hasDeathrattle = entity.has(tag: .deathrattle)
        hasPoisonous = entity.has(tag: .poisonous)
        hasDivineShield = entity.has(tag: .divine_shield)
        hasVenomous = entity.has(tag: .venomous)
    }

    init(card: Card, attack: Int, health: Int, isPremium: Bool) {
        cardId = card.id
        self.attack = attack
        self.health = health
        originalAttack = isPremium ? card.attack * 2 : card.attack
        originalHealth = isPremium ? card.health * 2 : card.health
        self.isPremium = isPremium
    }
}

class BattlegroundsMinionView: NSView {
    var entity: Entity? {
        didSet {
            display = entity.map { BattlegroundsMinionDisplay(entity: $0) }
        }
    }
    var display: BattlegroundsMinionDisplay?
    var sourceCardImage: NSImage?
    @IBInspectable var myIntrinsicSize: CGSize = CGSize(width: 100.0, height: 110.0)
    
    override var intrinsicContentSize: NSSize {
        return myIntrinsicSize
    }
    
    init() {
        super.init(frame: NSRect.zero)
        clipsToBounds = true
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        clipsToBounds = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        assertMainThread()
        super.draw(dirtyRect)
        let backgroundColor: NSColor = NSColor.clear
        
        backgroundColor.set()
        dirtyRect.fill()
        
        guard let display = display else {
            return
        }
        
        let rect = NSRect(x: 0, y: 0, width: 300, height: 350)
        
        let image = NSImage(size: NSSize(width: 300, height: 350), flipped: false, drawingHandler: { [self] _ -> Bool in
        
        let premium = display.isPremium ? "_premium" : ""
        let reborn = display.hasReborn
        let taunt = display.hasTaunt
        let deathrattle = display.hasDeathrattle
//        let legendary = entity.card.rarity == Rarity.legendary
        let poisonous = display.hasPoisonous
        let divineShield = display.hasDivineShield
        let venomous = display.hasVenomous
        // always hide for now, seems like TRIGGER_VISUAL is a bit too common to be useful
//        let trigger = entity.has(tag: GameTag.trigger_visual)
        
        if taunt, let tauntImage = NSImage(named: "taunt\(premium)") {
            tauntImage.draw(in: rect)
        }
        if let cardImage = ImageUtils.cachedArt(cardId: display.cardId) {
            NSGraphicsContext.saveGraphicsState()
            let ovalRect = NSRect(x: 55, y: 55, width: 190, height: 256)
            
            let path = NSBezierPath(ovalIn: ovalRect)
            path.addClip()
            
            cardImage.draw(in: NSRect(x: 10, y: 60, width: 280, height: 250))
            
            NSGraphicsContext.restoreGraphicsState()
        } else {
            ImageUtils.art(for: display.cardId, completion: { (img: NSImage?) in
                if img  != nil {
                    DispatchQueue.main.async {
                        self.needsDisplay = true
                    }
                }
            })
        }
        
        if let borderImage = NSImage(named: "border\(premium)") {
            borderImage.draw(in: rect)
        }
        
        if reborn, let rebornImage = NSImage(named: "reborn") {
            rebornImage.draw(in: rect)
        }
        
//        if legendary, let legendaryImage = NSImage(named: "legendary\(premium)") {
//            legendaryImage.draw(in: rect)
//        }
        
        if deathrattle, let deathrattleImage = NSImage(named: "deathrattle") {
            deathrattleImage.draw(in: rect)
        }
        
//        if trigger, let triggerImage = NSImage(named: "trigger") {
//            triggerImage.draw(in: rect)
//        }
        
        if poisonous, let poisonousImage = NSImage(named: "poisonous") {
            poisonousImage.draw(in: rect)
        }
        
        if venomous, let venomousImage = NSImage(named: "venomous") {
            venomousImage.draw(in: rect)
        }
        
        if let statsImage = NSImage(named: "stats\(premium)") {
            statsImage.draw(in: rect)
        }
        
        if divineShield, let divineShieldImage = NSImage(named: "divine-shield") {
            divineShieldImage.draw(in: rect) //NSRect(x: 30, y: 35, width: 240, height: 290))
        }
        
        var color = NSColor.white
        
        if display.attack > display.originalAttack {
            color = NSColor(red: 0.109, green: 0.89, blue: 0.109, alpha: 1.0)
        }
        drawText(text: display.attack.description, rect: NSRect(x: 45, y: 90, width: 90, height: 45), color: color)
        
        color = NSColor.white
        if display.health > display.originalHealth {
            color = NSColor(red: 0.109, green: 0.89, blue: 0.109, alpha: 1.0)
        }
        drawText(text: display.health.description, rect: NSRect(x: 165, y: 90, width: 90, height: 45), color: color)
        
        return true
        })
        
        image.draw(in: visibleRect  )
    }
    
    func drawText(text: String, rect: NSRect, color: NSColor) {
        if let font = NSFont(name: "ChunkFive", size: 45) {
            var attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color,
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
}
