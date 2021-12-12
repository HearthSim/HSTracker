//
//  MercenariesAbilityView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/9/21.
//  Copyright © 2021 Benjamin Michotte. All rights reserved.
//

import Foundation

struct MercenariesAbilityViewModel {
    var entity: Entity?
    var card: Card?
    var active: Bool
    var gameTurn: Int
    
    init(data: MercAbilityData) {
        card = data.card
        entity = data.entity
        active = data.active
        gameTurn = data.gameTurn
    }
    
    var turnsElapsed: Int {
        return max(0, gameTurn - 1)
    }
    
    var cooldown: Int {
        return entity?[.lettuce_current_cooldown] ?? max(0, (card?.mercenariesAbilityCooldown ?? 0) - turnsElapsed)
    }
    
    var speed: Int {
        return entity?[.cost] ?? card?.cost ?? 0
    }
    
    var baseSpeed: Int {
        return entity?.card.cost ?? card?.cost ?? 0
    }
    
    var opacity: Double {
        return cooldown > 0 ? 0.5 : 1.0
    }
    
    var checkmarkImage: String? {
        return active ? "checkmark" : nil
    }
    
    var cooldownImage: String? {
        return cooldown > 0 ? "merc_hourglass" : nil
    }
    
    var cooldownShadingVisibility: Bool {
        return cooldown > 0
    }
    
    var cooldownText: String? {
        return cooldown > 0 ? cooldown.description : nil
    }
    
    var speedText: String {
        return speed.description
    }
    
    var speedUncertainIndicatorVisibility: Bool {
        return entity == nil
    }
    
    var speedColor: NSColor {
        return speed > baseSpeed ? NSColor.red : speed < baseSpeed ? NSColor.green : NSColor.white
    }
    
    var cardId: String? {
        return entity?.cardId ?? card?.id ?? nil
    }
}

class MercenaryAbilityView: NSImageView {
    let vm: MercenariesAbilityViewModel
    
    init(frame: NSRect, data: MercenariesAbilityViewModel) {
        vm = data
        super.init(frame: frame)
        
        render()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render() {
        let rect = NSRect(x: 0, y: 0, width: 256, height: 256)
        
        let image = NSImage.init(size: NSSize(width: rect.width, height: 280))

        image.lockFocus()
        
        if vm.active {
            let activeIndicator = NSBezierPath(ovalIn: NSRect(x: -8, y: -10, width: 270, height: 270))
            NSColor.green.setFill()
            NSColor.green.setStroke()
            activeIndicator.fill()
            activeIndicator.stroke()
        }
        
        if let cardId = vm.cardId {
            if let cardImage = ImageUtils.cachedArt(cardId: cardId) {
                NSGraphicsContext.saveGraphicsState()
                
                let path = NSBezierPath(ovalIn: NSRect(x: 21, y: 21, width: 200, height: 200))
                path.addClip()
                
                cardImage.draw(in: rect)
                
                NSGraphicsContext.restoreGraphicsState()
            } else {
                ImageUtils.art(for: cardId, completion: { (img: NSImage?) in
                    if img  != nil {
                        DispatchQueue.main.async {
                            self.render()
                        }
                    }
                })
            }
        }
        
        if let abilityFrame = NSImage(named: "merc_ability") {
            abilityFrame.draw(in: rect)
        }
        
        let cooldownShadingColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        
        if vm.cooldownShadingVisibility {
            let cooldownShading = NSBezierPath(ovalIn: NSRect(x: 0, y: 0, width: 256, height: 256))
            cooldownShadingColor.setFill()
            cooldownShading.fill()
        }
        
        if let cooldownImage = vm.cooldownImage {
            let image = NSImage(named: cooldownImage)?.rotated(by: -20)
            image?.draw(in: NSRect(x: 256-40-70, y: 256-120+21, width: 120, height: 120))
        }
        
        if let checkmarkImage = vm.checkmarkImage {
            let image = NSImage(named: checkmarkImage)
            image?.draw(in: NSRect(x: 65, y: 256+40-80, width: 110, height: 80))
        }
        
        if let cooldownText = vm.cooldownText {
            drawText(text: cooldownText, rect: NSRect(x: 256-30-100, y: 256+9-85, width: 100, height: 100), color: NSColor.white, size: 100, stroke: -3)
        }
        
        drawText(text: vm.speedText, rect: NSRect(x: 40, y: 10, width: 150, height: 150), color: vm.speedColor, size: 100, stroke: -3)
        if vm.cooldownShadingVisibility {
            drawText(text: vm.speedText, rect: NSRect(x: 40, y: 10, width: 150, height: 150), color: cooldownShadingColor, size: 100, stroke: -3)
        }
        
        if vm.speedUncertainIndicatorVisibility {
            drawText(text: "?", rect: NSRect(x: 160, y: 10, width: 120, height: 120), color: NSColor.white, size: 90, stroke: -2)
            if vm.cooldownShadingVisibility {
                drawText(text: "?", rect: NSRect(x: 160, y: 10, width: 120, height: 120), color: cooldownShadingColor, size: 90, stroke: -2)
            }
        }

        image.unlockFocus()
        
        self.image = image
    }
    
    func drawText(text: String, rect: NSRect, color: NSColor, size: CGFloat, stroke: Int) {
        if let font = NSFont(name: "ChunkFive", size: size) {
            var attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color,
                .strokeWidth: stroke,
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
