//
//  BattlegroundsCompositionPopularity.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/17/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation

class BattlegroundsCompositionPopularity: NSView {
    @IBOutlet weak var contentView: NSView!
    
    @IBOutlet weak var items: NSStackView!
    @IBOutlet weak var noDataLabel: NSTextField!
    
    var viewModel: BattlegroundsCompositionPopularityViewModel?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("BattlegroundsCompositionPopularity", owner: self, topLevelObjects: nil)
        translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        contentView.frame = self.bounds
        
        update()
    }
    
    func update() {
        if let viewModel {
            noDataLabel.isHidden = true
            items.isHidden = false
            
            for subView in items.subviews {
                subView.removeFromSuperview()
            }
            for comp in viewModel.top3Compositions {
                let rect = NSRect(x: 0, y: 0, width: frame.width, height: 24)
                let view = BattlegroundsCompositionPopularityRow(frame: rect, viewModel: comp)
                items.addArrangedSubview(view)
            }
        } else {
            items.isHidden = true
            noDataLabel.isHidden = false
        }
    }
}
