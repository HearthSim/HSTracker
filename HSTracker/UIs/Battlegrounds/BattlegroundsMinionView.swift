//
//  BattlegroundsMinionView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/2/20.
//  Copyright © 2020 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsMinionView: NSView {
    var entity: Entity?
    var sourceCardImage: NSImage?
    
    init() {
        super.init(frame: NSRect.zero)
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let backgroundColor: NSColor = NSColor.clear
        
        backgroundColor.set()
        dirtyRect.fill()
        
        guard let entity = entity else {
            return
        }
        
        let rect = NSRect(x: 0, y: 0, width: 300, height: 350)
        
        let image = NSImage.init(size: NSSize(width: 300, height: 350))

        image.lockFocus()
        
        let isPremium = entity.has(tag: GameTag.premium)
        let premium = isPremium ? "_premium" : ""
        let taunt = entity.has(tag: GameTag.taunt)
        let deathrattle = entity.has(tag: GameTag.deathrattle)
        let legendary = entity.card.rarity == Rarity.legendary
        let poisonous = entity.has(tag: GameTag.poisonous)
        let divineShield = entity.has(tag: GameTag.divine_shield)
        
        if taunt, let tauntImage = NSImage(named: "taunt\(premium)") {
            tauntImage.draw(in: rect)
        }
        if let cardImage = ImageUtils.cachedArt(cardId: entity.cardId) {
            NSGraphicsContext.saveGraphicsState()
            let ovalRect = NSRect(x: 55, y: 55, width: 190, height: 256)
            
            let path = NSBezierPath(ovalIn: ovalRect)
            path.addClip()
            
            cardImage.draw(in: NSRect(x: 10, y: 60, width: 280, height: 250))
            
            NSGraphicsContext.restoreGraphicsState()
        } else {
            ImageUtils.art(for: entity.cardId, completion: { (img: NSImage?) in
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
        
        if deathrattle, let deathrattleImage = NSImage(named: "deathrattle") {
            deathrattleImage.draw(in: rect)
        }
        
        if legendary, let legendaryImage = NSImage(named: "legendary\(premium)") {
            legendaryImage.draw(in: rect)
        }
        
        if poisonous, let poisonousImage = NSImage(named: "poisonous") {
            poisonousImage.draw(in: rect)
        }
        
        if divineShield, let divineShieldImage = NSImage(named: "divine-shield") {
            divineShieldImage.draw(in: rect) //NSRect(x: 30, y: 35, width: 240, height: 290))
        }
        
        var color = NSColor.white
        
        let originalAttack = isPremium ? entity.card.attack * 2 : entity.card.attack
        let originalHealth = isPremium ? entity.card.health * 2 : entity.card.health
        if entity.attack > originalAttack {
            color = NSColor(red: 0.109, green: 0.89, blue: 0.109, alpha: 1.0)
        }
        drawText(text: entity.attack.description, rect: NSRect(x: 45, y: 90, width: 90, height: 45), color: color)
        
        color = NSColor.white
        if entity.health > originalHealth {
            color = NSColor(red: 0.109, green: 0.89, blue: 0.109, alpha: 1.0)
        }
        drawText(text: entity.health.description, rect: NSRect(x: 165, y: 90, width: 90, height: 45), color: color)
        
        image.unlockFocus()
        
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
