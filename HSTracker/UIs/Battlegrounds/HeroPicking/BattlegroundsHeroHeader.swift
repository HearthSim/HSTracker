//
//  BattlegroundsHeroHeader.swift
//  HSTracker
//
//  Created by Francisco Moraes on 12/20/22.
//  Copyright © 2022 Benjamin Michotte. All rights reserved.
//

import Foundation
import CustomToolTip

class BattlegroundsHeroHeader: NSView {
    @IBOutlet var contentView: NSView!
    @IBOutlet var avgPlacementTooltip: NSView!
    @IBOutlet var pickRateTooltip: NSView!
    
    @IBOutlet var avgPlacementTracker: NSView!
    @IBOutlet var avgPlacementLabel: NSTextField!
    @IBOutlet var tierBox: NSBox!
    @IBOutlet var tierLabel: NSTextField!
    @IBOutlet var pickRateTracker: NSView!
    @IBOutlet var pickRateLabel: NSTextField!
    
    @IBOutlet var placementDistribution: BattlegroundsPlacementDistribution!
    
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
    
    @objc dynamic var tierTooltipTitle: String = ""

    @objc dynamic var tierTooltipText: String = ""

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
        defaultBackgroundColor = .clear
        
        avgPlacementTracker.customToolTip = avgPlacementTooltip
        avgPlacementTracker.customToolTipMargins = CGSize(width: 0, height: 0)
        avgPlacementTracker.customToolTipInsets = CGSize(width: 25, height: 0)
        avgPlacementTooltip.updateTrackingAreas_CustomToolTip()
        
        pickRateTracker.customToolTip = pickRateTooltip
        pickRateTracker.customToolTipMargins = CGSize(width: 0, height: 0)
        pickRateTracker.customToolTipInsets = CGSize(width: 25, height: 0)
        pickRateTooltip.updateTrackingAreas_CustomToolTip()
        
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
        if let tier = viewModel?.tierChar {
            tierLabel.stringValue = tier
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
        
        tierTooltipTitle = viewModel?.tierTooltipTitle ?? ""
        tierTooltipText = viewModel?.tierTooltipText ?? ""
    }
}
