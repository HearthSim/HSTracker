//
//  BattlegroundsSingleHeroStats.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/26/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsSingleHeroStats: NSView {
    @IBOutlet weak var contentView: NSView!
    
    @IBOutlet weak var battlegroundsHeroHeader: BattlegroundsHeroHeader!
    @IBOutlet weak var heroPortraitContainer: NSView!
    @IBOutlet weak var armorTierLabel: NSTextField!
    @IBOutlet weak var compositions: BattlegroundsCompositionPopularity!
    
    @IBOutlet weak var armorTierTooltipRange: NSView!
    
    let viewModel: BattlegroundsSingleHeroViewModel
    
    override var intrinsicContentSize: NSSize {
        return NSSize(width: 266, height: 480)
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    init(frame frameRect: NSRect, viewModel: BattlegroundsSingleHeroViewModel) {
        self.viewModel = viewModel
        super.init(frame: frameRect)
        commonInit()
    }
    
    func commonInit() {
        Bundle.main.loadNibNamed("BattlegroundsSingleHeroStats", owner: self, topLevelObjects: nil)
        translatesAutoresizingMaskIntoConstraints = true
        contentView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(contentView)
        contentView.frame = self.bounds

//        heroPortraitContainer.customToolTip = armorTierTooltipRange
        
        compositions.viewModel = viewModel.bgsCompsPopularityVM
        battlegroundsHeroHeader.viewModel = viewModel.bgsHeroHeaderVM
        
        update()
    }
    
    func update() {
        battlegroundsHeroHeader.isHidden =  !viewModel.heroPowerVisibility
        if let armorTier = viewModel.armorTier {
            armorTierLabel.intValue = Int32(armorTier)
        } else {
            armorTierLabel.stringValue = "—" // em dash
        }
        compositions.update()
    }
    
}
