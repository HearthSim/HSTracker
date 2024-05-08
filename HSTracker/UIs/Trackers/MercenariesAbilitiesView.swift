//
//  MercenariesAbilitiesView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 11/9/21.
//  Copyright © 2021 Benjamin Michotte. All rights reserved.
//

import Foundation

class MercenariesAbilitiesView: NSView {
    var mercAbilities =  [MercenariesAbilityViewModel]()
    
    init() {
        super.init(frame: NSRect.zero)
        
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setAbilities(abilities: [MercAbilityData]?, abilitySize: Double, parentFrame: NSRect) {
        let newAbilities = abilities?.map { x in MercenariesAbilityViewModel(data: x) } ?? [MercenariesAbilityViewModel]()
        if newAbilities.count == mercAbilities.count {
            var found = false
            for i in 0 ..< newAbilities.count {
                let a = mercAbilities[i]
                let b = newAbilities[i]
                if a.entity != b.entity ||
                    a.card != b.card ||
                    a.cardId != b.cardId ||
                    a.active != b.active ||
                    a.turnsElapsed != b.turnsElapsed ||
                    a.cooldown != b.cooldown ||
                    a.speed != b.speed ||
                    a.cooldown != b.cooldown {
                    found = true
                    break
                }
            }
            if !found {
                return
            }
        }
        mercAbilities = newAbilities
        for view in subviews {
            view.removeFromSuperview()
        }
        let size = min(abilitySize, min(parentFrame.width / 3.0, parentFrame.height))
        let frame = size > 0 ? NSRect(x: (parentFrame.width - Double(newAbilities.count) * size) / 2, y: 0, width: size, height: parentFrame.height) : NSRect.zero
        for i in 0 ..< newAbilities.count {
            let abilityView = MercenaryAbilityView(frame: frame.offsetBy(dx: CGFloat(i) * size, dy: 0), data: newAbilities[i])
            addSubview(abilityView)
        }
    }
}
