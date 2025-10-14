//
//  BattlegroundsSingleHeroStats.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/26/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation
import SwiftUI

class BattlegroundsSingleHeroStats: NSView {
    @IBOutlet var contentView: NSView!
    
    @IBOutlet var battlegroundsHeroHeader: NSView!
    @IBOutlet var heroPortraitContainer: NSView!
    @IBOutlet var compositions: BattlegroundsCompositionPopularity!
    
    @IBOutlet var armorTierTooltipRange: NSView!
    
    let viewModel: BattlegroundsSingleHeroViewModel
    
    var setSelectedHeroDbfIdCommand: ((_ heroId: Int) -> Void)?
    
    @objc dynamic var compositionsVisibility: Bool {
        return false //viewModel.compositionsVisibility
    }
    
    override var intrinsicContentSize: NSSize {
        return NSSize(width: 266, height: 568)
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
        NibHelper.loadNib(Self.self, self)
        
        translatesAutoresizingMaskIntoConstraints = true
        contentView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(contentView)
        contentView.frame = self.bounds
        
        viewModel.propertyChanged = { name in
            DispatchQueue.main.async {
                self.update(name)
            }
        }

//        heroPortraitContainer.customToolTip = armorTierTooltipRange
        
        let trackingArea = NSTrackingArea(rect: NSRect.zero,
                                          options: [NSTrackingArea.Options.inVisibleRect, NSTrackingArea.Options.activeAlways, NSTrackingArea.Options.mouseEnteredAndExited],
                                          owner: self,
                                          userInfo: nil)
        heroPortraitContainer.addTrackingArea(trackingArea)

        compositions.viewModel = viewModel.bgsCompsPopularityVM
        
        let heroStatFrame = NSRect(x: 28, y: 470, width: 236, height: 72);
        if #available(macOS 10.15, *) {
            battlegroundsHeroHeader = NSHostingView(rootView: BattlegroundsStatsPicker(viewModel: viewModel.bgsHeroHeaderVM))
            battlegroundsHeroHeader.frame = heroStatFrame
        } else {
            let view = BattlegroundsHeroHeader(frame: heroStatFrame)
            view.viewModel = viewModel.bgsHeroHeaderVM
            battlegroundsHeroHeader = view
        }
        addSubview(battlegroundsHeroHeader)
        
        update()
    }
    
    func update(_ property: String? = nil) {
        battlegroundsHeroHeader.isHidden =  !viewModel.heroPowerVisibility
        if property == nil {
            compositions.update()
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        if let id = viewModel.heroDbfId {
            setSelectedHeroDbfIdCommand?(id)
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        setSelectedHeroDbfIdCommand?(0)
    }
}
