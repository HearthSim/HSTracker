//
//  CardCell.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 3/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class CardCell: JNWCollectionViewCell {

    private var _card: Card?
    var showCard = true
    var isArena = false
    var cellView: CardBar?

    func set(card: Card) {
        _card = card
        if showCard {
            if let cellView = cellView {
                cellView.removeFromSuperview()
                self.cellView = nil
            }
            self.backgroundImage = ImageUtils.image(for: card.id)
        } else {
            if let cellView = cellView {
                cellView.card = card
            } else {
                cellView = CardBar.factory()
                cellView?.frame = NSRect(x: 0, y: 0,
                                         width: CGFloat(kFrameWidth),
                                         height: CGFloat(kRowHeight))
                cellView?.card = card
                cellView?.playerType = .cardList
                self.addSubview(cellView!)
            }
        }
    }
    var card: Card? {
        return _card
    }

    func set(count: Int) {
        var alpha: Float = 1.0
        if !isArena {
            if count == 2 || (count == 1 && _card!.rarity == .legendary) {
                alpha = 0.5
            }
        }
        self.layer!.opacity = alpha
        self.layer!.setNeedsDisplay()
    }
    
    func flash() {
        if !showCard {
            return
        }
        
        self.layer!.masksToBounds = false
        self.layerUsesCoreImageFilters = true
        
        // glow
        let glowFilter = GlowFilter()
        glowFilter.glowColor = CIColor(red: 0, green: 0, blue: 0, alpha: 1)
        glowFilter.strength = 0.0
        glowFilter.inputRadius = 20
        glowFilter.name = "glow"
        
        // exposure
        let expFilter: CIFilter = CIFilter(name: "CIExposureAdjust")!
        expFilter.setDefaults()
        expFilter.setValue(NSNumber(value: 0), forKey: "inputEV")
        expFilter.name = "exposure"
        self.layer!.filters = [expFilter, glowFilter]
        
        let expAnim: CABasicAnimation = CABasicAnimation()
        expAnim.keyPath = "filters.exposure.inputEV"
        expAnim.fromValue = NSNumber(value: 5.0)
        expAnim.toValue = NSNumber(value: 0.0)
        expAnim.duration = 0.5
        
        let glowAnim: CABasicAnimation = CABasicAnimation()
        glowAnim.keyPath = "filters.glow.strength"
        glowAnim.fromValue = NSNumber(value: 0.1)
        glowAnim.toValue = NSNumber(value: 0.0)
        glowAnim.duration = 0.5

        let animgroup: CAAnimationGroup = CAAnimationGroup()
        animgroup.animations = [expAnim, glowAnim]
        animgroup.duration = 0.35
        
        self.layer!.add(animgroup, forKey: "animgroup")
        
        // final value
        self.layer!.setValue(NSNumber(value: 0), forKey: "filters.exposure.inputEV")
        self.layer!.setValue(NSNumber(value: 0), forKey: "filters.glow.strength")
    }
}
