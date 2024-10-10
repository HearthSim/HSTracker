//
//  ActiveEffects.swift
//  HSTracker
//
//  Created by Francisco Moraes on 10/8/24.
//  Copyright © 2024 Benjamin Michotte. All rights reserved.
//

import Foundation

class ActiveEffectsOverlay: OverWindowController {
    
    @IBOutlet weak var grid: NSGridView!
    
    private(set) var _activeEffects: ActiveEffects!
    private(set) var visibleEffects = [ActiveEffect]()
    var isPlayer = false
    
    @objc dynamic var visibility = false
    
    override init(window: NSWindow?) {
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setActiveEffects(_ activeEffects: ActiveEffects) {
        _activeEffects = activeEffects
    }

    func updateVisibleEffects() {
        DispatchQueue.main.async { [self] in
            visibleEffects.removeAll()
            let effectsByCardId = _activeEffects.getVisibleEffects(controlledByPlayer: isPlayer).group({ x in x.cardId })
            
            for effects in effectsByCardId.values {
                let effect = effects[0]
                let effectCount = effects.count
                let effectWithCount = ActiveEffect(effect, isPlayer, nil)
                
                if effect.showNumberInPlay && effectCount > 1 {
                    effectWithCount.count = effectCount as NSNumber
                }
                
                visibleEffects.append(effectWithCount)
            }
            
            // updates
            updateGrid()
        }
    }
    
    func updateGrid() {
        guard let grid else {
            return
        }
        while grid.numberOfRows > 0 {
            grid.removeRow(at: 0)
        }
        while grid.numberOfColumns > 0 {
            grid.removeColumn(at: 0)
        }
        for subview in grid.subviews {
            subview.removeFromSuperview()
        }
        
        var array = [ActiveEffect]()
        var index = 0
        while index < 4 && index < visibleEffects.count {
            array.append(visibleEffects[index])
            index += 1
        }
        grid.addRow(with: array)
        array.removeAll()
        while index < 8 && index < visibleEffects.count {
            array.append(visibleEffects[index])
            index += 1
        }
        grid.addRow(with: array)
        for r in 0 ..< grid.numberOfRows {
            grid.row(at: r).height = 61
        }
        for c in 0 ..< grid.numberOfColumns {
            grid.column(at: c).width = 61
        }
    }
    
    func forceShowExampleEffects(_ isPlayer: Bool) {
        visibleEffects.removeAll()
        let preparation = PreparationEnchantment(entityId: 0, isControlledByPlayer: isPlayer)
        for _ in 0 ..< 4 {
            visibleEffects.append(ActiveEffect(preparation, isPlayer, nil))
        }
        let wave = WaveOfApathyEnchantment(entityId: 0, isControlledByPlayer: isPlayer)
        for _ in 0 ..< 4 {
            visibleEffects.append(ActiveEffect(wave, isPlayer, 3))
        }
        updateGrid()
        // updates
    }
    
    func forceHideExampleEffects() {
        updateVisibleEffects()
    }
    
    func reset() {
        _activeEffects.reset()
        updateVisibleEffects()
    }
}
