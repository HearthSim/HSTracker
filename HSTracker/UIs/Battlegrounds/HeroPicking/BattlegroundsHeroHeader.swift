//
//  BattlegroundsHeroHeader.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/20/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation
//import CustomToolTip

class BattlegroundsHeroHeader: NSView {
    @IBOutlet weak var contentView: NSView!
    @IBOutlet weak var tooltip: NSView!
    
    @IBOutlet weak var avgPlacementTracker: NSView!
    @IBOutlet weak var avgPlacementLabel: NSTextField!
    @IBOutlet weak var tierBox: NSBox!
    @IBOutlet weak var tierLabel: NSTextField!
    @IBOutlet weak var pickRateLabel: NSTextField!
    
    @IBOutlet weak var placementDistribution: BattlegroundsPlacementDistribution!
    
    var viewModel: BattlegroundsHeroHeaderViewModel? {
        didSet {
            viewModel?.propertyChanged = { _ in
                DispatchQueue.main.async {
                    self.update()
                }
            }
            DispatchQueue.main.async {
                self.update()
            }
        }
    }
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        Bundle.main.loadNibNamed("BattlegroundsHeroHeader", owner: self, topLevelObjects: nil)
        translatesAutoresizingMaskIntoConstraints = true
        contentView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(contentView)
        contentView.frame = self.bounds
        
//        contentView.customToolTip = tooltip
//        contentView.customToolTipMargins = CGSize(width: 0, height: 0)
        
        let trackingArea = NSTrackingArea(rect: NSRect.zero,
                                          options: [NSTrackingArea.Options.inVisibleRect, NSTrackingArea.Options.activeAlways, NSTrackingArea.Options.mouseEnteredAndExited],
                                          owner: self,
                                          userInfo: nil)
        avgPlacementTracker.addTrackingArea(trackingArea)
    }
    
    override func mouseEntered(with event: NSEvent) {
        if #available(macOS 10.15.0, *) {
            Task.init {
                if await Debounce.wasCalledAgain(milliseconds: 100, callerMemberName: "AvgPlacementTrigger") {
                    return
                }
                viewModel?.onPlacementHover?(true)
            }
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if #available(macOS 10.15.0, *) {
            Task.init {
                if await Debounce.wasCalledAgain(milliseconds: 100, callerMemberName: "AvgPlacementTrigger") {
                    return
                }
                viewModel?.onPlacementHover?(false)
            }
        }
    }
    
    func update() {
        logger.debug(#function)
        avgPlacementLabel.textColor = NSColor.fromHexString(hex: viewModel?.avgPlacementColor ?? "#FFFFFF") ?? NSColor.white
        if let avg = viewModel?.avgPlacement {
            avgPlacementLabel.doubleValue = avg
        } else {
            avgPlacementLabel.stringValue = "—" // em dash
        }
        
        tierBox.wantsLayer = true
        tierBox.layer = viewModel?.tierGradient
        if let tier = viewModel?.tier {
            tierLabel.intValue = Int32(tier)
        } else {
            tierLabel.stringValue = "—" // em dash
        }
        
        if let pickRate = viewModel?.pickRate {
            pickRateLabel.doubleValue = pickRate / 100.0
        } else {
            pickRateLabel.stringValue = "—" // em dash
        }
        
        placementDistribution.isHidden = !(viewModel?.placementDistributionVisibility ?? false)
        
        if viewModel?.placementDistributionVisibility ?? false, let values = viewModel?.placementDistribution {
            placementDistribution.values = values
        }
    }
}
