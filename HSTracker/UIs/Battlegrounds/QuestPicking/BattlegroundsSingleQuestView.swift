//
//  BattlegroundsSingleQuestView.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/14/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsSingleQuestView: NSView {
    @IBOutlet weak var contentView: NSView!
    
    @IBOutlet weak var avgPlacementLabel: NSTextField!
    
    @IBOutlet weak var tierBox: NSBox!
    @IBOutlet weak var tierLabel: NSTextField!
    
    @IBOutlet weak var pickRateLabel: NSTextField!
    
    @IBOutlet weak var compositionView: BattlegroundsCompositionPopularity!
    
    let viewModel: BattlegroundsSingleQuestViewModel
    
    override var intrinsicContentSize: NSSize {
        return NSSize(width: 254, height: 880)
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    init(frame frameRect: NSRect, viewModel: BattlegroundsSingleQuestViewModel) {
        self.viewModel = viewModel
        super.init(frame: frameRect)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("BattlegroundsSingleQuestView", owner: self, topLevelObjects: nil)
        translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.frame = self.bounds
        
        compositionView.viewModel = viewModel.compVM
        
        update()
        
        compositionView.update()
    }
    
    func update() {
        avgPlacementLabel.textColor = NSColor.fromHexString(hex: viewModel.avgPlacementColor) ?? NSColor.white
        if let avg = viewModel.avgPlacement {
            avgPlacementLabel.doubleValue = avg
        } else {
            avgPlacementLabel.stringValue = "—" // em dash
        }
        
        tierBox.wantsLayer = true
        tierBox.layer = viewModel.tierGradient
        if let tier = viewModel.tier {
            tierLabel.intValue = Int32(tier)
        } else {
            tierLabel.stringValue = "—" // em dash
        }
        
        if let pickRate = viewModel.pickRate {
            pickRateLabel.doubleValue = pickRate / 100.0
        } else {
            pickRateLabel.stringValue = "—" // em dash
        }
    }
}
